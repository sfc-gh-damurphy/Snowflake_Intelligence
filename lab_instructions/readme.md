# Snowflake Intelligence HOL

Snowflake Intelligence, a new application, empowers users to create and interact with data

agents. These agents can access data from platforms like Snowflake and Salesforce to

generate visualizations and simple applications and facilitate action on insights. Powered by

Cortex LLM functions, Analyst, and Search, Snowflake Intelligence offers a curated,

enterprise-ready application experience.



The ideal customer profile for a Snowflake Intelligence user is a business user, such as a sales

rep, executive, or marketing manager, who is looking for insights and to take action based on

data in their organization. Traditionally, they would have relied on BI applications or manually

navigated file search (like SharePoint and Google Drive) and taken manual actions that can now

be enhanced and automated with data agents.



Snowflake Intelligence is currently under development, and while some workflows in this lab

may evolve as we approach production and refine our strategy, the foundational elements like

semantic models, agents, and search services will persist. This lab will be updated periodically

to reflect the product's progress. It represents the state of Snowflake Intelligence leading up to

Summit 2025, as we aimed to provide this training beforehand.

What you’ll do:

It is recommended that you download this document from Compass and run it from your

GDrive. That will make copying and pasting a lot easier, as sometimes formatting can go wrong

when copying and pasting directly from Compass.



This lab explores accessing festival data (ticket sales, customer details, events) and a parsed

result of multiple bands' contract information. We'll join these datasets and build a semantic

model using synonyms and defining relationships among the tables. This model will then be

used in a prompt to retrieve data from Snowflake for end users via a simple chat-like interface.

Consequently, users can obtain answers and data visualizations without needing SQL

knowledge, understanding unstructured data queries, or data modeling concepts.



Below is an outline of the lab:

●  Ingest data into a database

●  Create a simple agent

●  Create a semantic layer

●  Create a smarter agent using the semantic layer

●  Create a search service

●  Update the smart agent to also use the search service

●  Utilize Snowflake Intelligence



Created by: SE Enablement (Dan Murphy)            July 2025


---

Why it matters:

●  Self-serve data exploration: Create charts and get instant answers using natural

language. With an intuitive interface powered by agentic AI, enable teams to discover

trends and analyze data without technical expertise or waiting for custom dashboards.

●  Democratize intelligence: Access and analyze thousands of data sources

simultaneously, going beyond basic AI tools that only handle single documents.

●  Comprehensive integration: Seamlessly analyze structured and unstructured data

together. Connect insights from spreadsheets, documents, images, and databases

simultaneously.

●  Automatic security: Existing Snowflake security controls, including role-based access

and data masking, automatically apply to all AI interactions and conversations.

Step 1: Snowflake Intelligence Setup

You will need to enable these features on your demo account. Do this by logging into the

deployment (snowflake.okta.com) and choosing the correct deployment for your account, and

then run this command. At this time, 5/15/25, this is the case, but this process will change in the

future.



SQL

alter account << account locator >>

set UI_ENABLE_AI_ML_FEATURE_19 = 'ENABLED'

, ENABLE_DATA_TO_ANSWER=true

, COPILOT_ORCHESTRATOR_PARAM_10='true'

, _DP_PEP_SI = true

, COPILOT_ORCHESTRATOR_PARAM_13='true'

, UI_ENABLE_AI_ML_FEATURE_29 = 'ENABLED'

, FEATURE_CORTEX_AGENT_ENTITY = 'ENABLED'

, CORTEX_REST_DATA_AGENT_API_ENABLE = true

, _DP_PEP_SI_ADMIN = true

, _DP_PEP_SI_ADMIN_CHAT = true

, _DP_PEP_SI_ENABLE_AGENT_OBJECTS = true

parameter_comment = 'Enable Snowflake Intelligence - SE Demo';





This will allow you to see the needed navigation in Snowsight.



Created by: SE Enablement (Dan Murphy)            July 2025


---





A few things to note:

●  If you go into Snowflake Intelligence at this point, it will just spin forever because we

have not set up the needed parts. This will change in the future, but at this time, this is

the case.

●  At this time, Snowflake Intelligence (SI) will utilize your default role. You need to make

sure this is set to the role we will create in the lab (directions below).

●  Snowflake Intelligence will also utilize your default warehouse, you must set this up for

SI to work.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 1](/images/image001.png)



---





Users in Snowflake Intelligence will map to Snowflake users. Over time, we will move the UI out
ai.Snowflake.com), but even

of Snowflake Snowsight and into a standalone experience (

there, Snowflake roles are planned to be leveraged for configuration. Users of Snowflake

Intelligence need a few layers of permissions:
config

1.  They need permission to SELECT on the  table that holds the agent's

configuration (this will likely disappear in the future, as we’ll store configuration

automatically).
temp

2.  They need permissions on the  schema, which is utilized for different operations

like file upload/parsing (this will also likely disappear in the future).

3.  They need permission to the underlying Cortex Search Service and the ability to call

Cortex Analyst.

4.  They need permission for any underlying data surfaced by an agent.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 2](/images/image002.png)



---

Important notes:

●  Users for Snowflake Intelligence need to have a default role and a default

warehouse.
Snowflake_intelligence

●  The database needs to be named .

Metadata Objects



Please create a new worksheet and run this script to create the roles and database objects

needed to store Snowflake Intelligence metadata. This will not be needed in the future.



SQL

use role accountadmin;



--ability to run across cloud if claude is not in your region:

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';



-- Create roles

create role Snowflake_intelligence_admin_rl;



--need to add ability to create databases

GRANT CREATE DATABASE ON ACCOUNT TO ROLE Snowflake_intelligence_admin_rl;



-- Warehouse that is going to be used for Cortex Search Service creation

as well as query execution.

create warehouse Snowflake_intelligence_wh with warehouse_size =

'X-SMALL';

grant usage on warehouse Snowflake_intelligence_wh to role

Snowflake_intelligence_admin_rl;



-- Create a database. This will hold configuration and other objects to

support Snowflake Intelligence.

create database Snowflake_intelligence;

grant ownership on database Snowflake_intelligence to role

Snowflake_intelligence_admin_rl;



-- Dynamically grant role 'Snowflake_intelligence_admin_rl' to the

current user

DECLARE

sql_command STRING;

Created by: SE Enablement (Dan Murphy)            July 2025


---

BEGIN

sql_command := 'GRANT ROLE Snowflake_intelligence_admin_rl TO USER

"' || CURRENT_USER() || '";';

EXECUTE IMMEDIATE sql_command;

RETURN 'Role Snowflake_intelligence_admin_rl granted successfully to

|| CURRENT_USER();

user '

END;



-- Set up stages and tables for configuration.

use role Snowflake_intelligence_admin_rl;

use database Snowflake_intelligence;



-- Set up a temp schema for file upload (only temporary stages will be

created here).

create or replace schema Snowflake_intelligence.temp;

grant usage on schema Snowflake_intelligence.temp to role public;



-- OPTIONAL: Set up stages and tables for configuration - you can have

your semantic models be anywhere else, just make sure that the users have

grants to them

create schema if not exists config;

use schema config;



create stage semantic_models encryption = (type = 'SNOWFLAKE_SSE');

Agent Configuration



This script is needed at this time to store all of your agent information. Please add this below

your above code, and then run. This creates an Agent Policy that allows you to control which

roles can see which agents.



SQL

use role Snowflake_intelligence_admin_rl;

create schema if not exists Snowflake_intelligence.agents;



-- Make SI agents in general discoverable to everyone.

Created by: SE Enablement (Dan Murphy)            July 2025


---

grant usage on schema Snowflake_intelligence.agents to role public;



CREATE OR REPLACE ROW ACCESS POLICY

Snowflake_intelligence.agents.agent_policy

AS (grantee_roles ARRAY) RETURNS BOOLEAN ->

ARRAY_SIZE(FILTER(grantee_roles::ARRAY(VARCHAR), role ->

is_role_in_session(role))) <> 0;



-- Create an agent config table. Multiple tables can be created to give

granular

-- UPDATE/INSERT permissions to different roles.

create or replace table Snowflake_intelligence.agents.config (

agent_name varchar not null,

agent_description varchar,

grantee_roles array not null,

tools array,

tool_resources object,

tool_choice object,

response_instruction varchar,

sample_questions array,

constraint pk_agent_name primary key (agent_name)

)

with row access policy Snowflake_intelligence.agents.agent_policy on

(grantee_roles);

grant select on table Snowflake_intelligence.agents.config to role

public;



Currently, Snowflake Intelligence uses your DEFAULT ROLE, so we need to change our

default role to the role we created from the above script. This role is called:

Snowflake_intelligence_admin_rl. This way, all objects will be owned by the correct role, and we

will not run into permission issues. Go ahead and change your default role to the newly created

role. You can do this by selecting your name at the bottom and going to switch role, and

choosing the Snowflake_intelligence_admin_rl, and when you hover over it, choose set as

default, and also make sure this is your selected role:

Created by: SE Enablement (Dan Murphy)            July 2025


---







Go ahead and log out of your account and log back in, sometimes this resolves some of the

permission issues and is a good way to check that your defaults have been set correctly.

Step 2: Load Festival Data

For our lab, we will use some made-up festival data. To support this, we will need to load

multiple tables. Please unzip the file below containing all the lab files and then import each as a

table into Snowflake through the UI.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 3](/images/image003.png)



![Extracted Image 4](/images/image004.png)



---



Snowflake Intelligence Festival Data.zip



Log into your Snowflake Demo Account and create a space for these tables to live through the

UI. Let’s create a database we will call it SI_EVENTS_HOL make sure to create it with the

role Snowflake_intelligence_admin_rl:











Let’s create the tables we need for this lab. There are a total of 4 tables needed for this lab, and

they can all be created the same way by creating a table from a file in Snowflake. Please repeat

the following steps for all four tables:



1.  Customers

2.  Contracts

3.  Ticket Sales

4.  Events



We will load these tables into the public schema.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 5](/images/image005.png)



![Extracted Image 6](/images/image006.png)



---



To load a table from a file in Snowsight, go into the SI_Events database we created, go to the

Public schema, and go into tables, and then click the create button on the top right to create a

table from a file:







Name each table the same name as the file you unzipped:



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 7](/images/image007.png)



![Extracted Image 8](/images/image008.png)



![Extracted Image 9](/images/image009.png)



---

Open the View Options section in the file format area and make sure that the header is the first

line of the document:













Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 10](/images/image010.png)



![Extracted Image 11](/images/image011.png)



![Extracted Image 12](/images/image012.png)



---

Repeat this for all 4 files so you have all 4 tables needed for the lab.  When you are complete,

you should see the following under tables in the public schema:



Configure DORA for Grading

Why Use DORA?

●  Automated Grading: DORA enables SE BPs to automatically grade hands-on

curriculum tasks, leveraging the grading framework created by the Training team.

Developer Relations also uses it for event labs.

●  Functionality: DORA allows SE BPs to write tests that validate the completion of

hands-on steps and track progress toward certification.

DORA API Integration Setup

1.  To submit grading requests via external functions, follow the steps below in a

new SQL worksheet in your Snowflake account.

SQL



USE ROLE ACCOUNTADMIN;



-- Create API integration

CREATE OR REPLACE API INTEGRATION dora_api_integration

API_PROVIDER = AWS_API_GATEWAY

API_AWS_ROLE_ARN =

'arn:aws:iam::321463406630:role/snowflakeLearnerAssumedRole'

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 13](/images/image013.png)



---

ENABLED = TRUE

API_ALLOWED_PREFIXES = (

'https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora'

);



-- Confirm integration

SHOW INTEGRATIONS;



-- Create utility database

CREATE OR REPLACE DATABASE util_db;



-- Create greeting function

CREATE OR REPLACE EXTERNAL FUNCTION util_db.public.se_greeting(

email VARCHAR,

firstname VARCHAR,

middlename VARCHAR,

lastname VARCHAR

)

RETURNS VARIANT

API_INTEGRATION = dora_api_integration

CONTEXT_HEADERS = (

CURRENT_TIMESTAMP,

CURRENT_ACCOUNT,

CURRENT_STATEMENT,

CURRENT_ACCOUNT_NAME

)

AS

;

'https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora/greeting'



-- Replace with your Snowflake details

-- Example:

-- SELECT util_db.public.se_greeting(

--   'dan.murphy@snowflake.com', 'Dan', '', 'Murphy');



SELECT util_db.public.se_greeting(

'your_email@Snowflake.com',

'Your First Name',

'Your Middle Name or empty string',

'Your Last Name'

);



-- Create grading function

CREATE OR REPLACE EXTERNAL FUNCTION util_db.public.se_grader(

step VARCHAR,

Created by: SE Enablement (Dan Murphy)            July 2025


---

passed BOOLEAN,

actual INTEGER,

expected INTEGER,

description VARCHAR

)

RETURNS VARIANT

API_INTEGRATION = dora_api_integration

CONTEXT_HEADERS = (

CURRENT_TIMESTAMP,

CURRENT_ACCOUNT,

CURRENT_STATEMENT,

CURRENT_ACCOUNT_NAME

)

AS

'https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora/grader';



grant usage on database util_db to role public;

grant usage on schema util_db.public to role public;

grant usage on function

util_db.public.se_grader(varchar,boolean,integer,integer,varchar) to role

public;



Created by: SE Enablement (Dan Murphy)            July 2025


---



✅ Expected Output: You should see confirmation messages after each CREATE

se_greeting function successfully.

statement and be able to run the



Step 3: Create a Simple Agent

What is an agent? Agentic AI is the buzzword of 2025, but with Snowflake agents, these are

tangible things we’re creating that will include one or more Cortex building blocks, like an

analyst semantic model or search service



Go to Snowflake, and the Agents section should now work with the config tables we created

above. The page will keep attempting to redraw at this point, but that is expected for now. Go

ahead and click on Create Agent.



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 14](/images/image014.png)



---





Let's create a very simple agent

●  Let's name it Claude

●  Let’s give it a Display name of Claude as well



Refresh the screen, and we will see the new agent created:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 15](/images/image015.png)



![Extracted Image 16](/images/image016.png)



---



Step 4: Go to Snowflake Intelligence

To easily navigate while using the Snowflake Intelligence application, open a new browser tab

specifically for Snowsight. This will allow you to switch between the standard Snowsight

interface and the Snowflake Intelligence application, which you can access via the Snowflake

Intelligence link. After clicking the link, the navigation will change to focus on Snowflake

Intelligence.



Now we can see our agent that we created in the dropdown and be able to interact with

Snowflake intelligence easily:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 17](/images/image017.png)



![Extracted Image 18](/images/image018.png)



---



I can also upload files as needed to have Claude look at the file and complete my analysis.



Go ahead and query Snowflake Intelligence. Let's ask this: What can you tell me about the

company Snowflake?



We have currently developed a basic agent lacking access to data within your Snowflake

account. It solely interacts with Claude. To enhance its intelligence, we need to integrate a

semantic model and connect it to the agent, thereby providing improved context.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 19](/images/image019.png)



![Extracted Image 20](/images/image020.png)



---

# Step 5: Create a Semantic Model

Let's now build a more intelligent agent that analyzes the data within Snowflake by utilizing our

semantic layer.



Lets create a semantic view using cortex analyst:





Go ahead and select create new:



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 21](/images/image021.png)



![Extracted Image 22](/images/image022.png)



---





We can choose the SI_EVENTS_HOL database and PUBLIC schema we created earlier Then

we can select Semantic Views and enter the following name and description



Name: Music_Festival

Description: This has information on music festivals, including locations, events, and ticket sales



Let's select our tables from the SI_EVENTS_HOL data that we imported at the beginning of the

lab:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 23](/images/image023.png)



---



Then we can select the columns to choose. Let's just select all columns by choosing the top

checkbox:



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 24](/images/image024.png)



![Extracted Image 25](/images/image025.png)



---

## View the Results

When we click ‘Create and Save’ it will generate a starter semantic model for us:





We can see that it has already created a description as well as some other details, like

synonyms. Let's go ahead and add ‘show’ and ‘concert’ to the list of synonyms for

EVENT_NAME in the EVENTS table:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 26](/images/image026.png)



---





Move Columns

The model incorrectly identified EVENT_ID as a fact due to its numerical data type, but it is

actually a dimensional column. This can be easily corrected by moving it to the dimensions

section in the edit menu. It is crucial to review and adjust the model after Snowflake's initial

column categorization.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 27](/images/image027.png)



---



We will need to do this for the following incorrectly identified columns:

1.  TICKET_SALES

a.  TICKET_ID - move to dimension

b.  EVENT_ID - move to dimension

c.  CUSTOMER_ID - move to dimension

2.  CUSTOMERS

a.  CUSTOMER_ID - move to dimension

3.  EVENTS

a.  EVENT_ID - move to dimension



We also need to assign unique values option to primary keys

We will do this for the following tables:

1.  Ticket_Sales

a.  Ticket_ID

2.  Customers

a.  Customer_ID

3.  Events

a.  Event_ID

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 28](/images/image028.png)



---

This is done by editing each dimension and then checking the box for unique identifier:



Do this for all the listed tables above.  Then you will need to save the semantic model and

refresh the page.



Test the Model

I can test this model right now by going to the side window and putting in the following prompt:

What are the different events in Europe



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 29](/images/image029.png)



![Extracted Image 30](/images/image030.png)



---

Then it will go against my model and then write SQL, and then execute that SQL against my

model:





b.



Define Table Relationships

We then need to define our relationships with the other tables. By default, no relationships are

created, but they are needed for more complex queries that span multiple tables.



When selecting the columns if you do not see your columns you might have missed the step

to make ID columns unique on the table please see above.  You might also just need to do a full

refresh on the page.



Our first relationship we will define is TICKET_SALES to EVENT.  For every EVENT, there are

many ticket sales, and the joining column is EVENT_ID. Let's define a relationship that

represents that:



Relationship Name: TicketSales_to_Events

Join Type: Inner

Relationship type: many_to_one

Left Table: Ticket_Sales

Right Table: Events

Relationship Columns: EVENT_ID and EVENT_ID

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 31](/images/image031.png)



---







Let's add a second relationship of customers to tickets:



Relationship Name: TicketSales_to_Customers

Join Type: Inner

Relationship type: many_to_one

Left Table: Customers

Right Table: Ticket_Sales

Relationship Columns: CUSTOMER_ID and CUSTOMER_ID



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 32](/images/image032.png)



![Extracted Image 33](/images/image033.png)



---





Now we have two relationships set up in our semantic model. Let's go ahead and test them

using the prompt on the right side. We can ask this: How many ticket sales were there for

Difficult Fest?

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 34](/images/image034.png)



---



We can see that it was able to utilize our join and see how many tickets were sold for that event

by joining the two tables together we defined in our relationship.



We can also ask it to ‘Count the total customers by customer region that went to Difficult Fest’,

and this should span all of our tables in our semantic model and give us values:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 35](/images/image035.png)



---



Excellent! This functionality is operating as anticipated.

Verify the Queries

Since these queries returned the correct values, we can add them as verified queries, which will

fuel our model's improvement.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 36](/images/image036.png)



---



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 37](/images/image037.png)



---





These will now show up under verified queries in our model definition:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 38](/images/image038.png)



---





Save the Model

When you are done, make sure you save the model:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 39](/images/image039.png)



---





Step 6: Create an Agent to Use the Semantic Model



Let's go back to the agents now and create a new Agent





We will use the following information:

Name: Music_Festival_Agent

Description: An agent that can return information about music festival events and ticket sales



After those are filled in, go ahead and click ‘+ Semantic Model’, and attach the semantic model

we created earlier.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 40](/images/image040.png)



![Extracted Image 41](/images/image041.png)



---





Then go ahead and edit the agent by click on it





Then go to edit:

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 42](/images/image042.png)



![Extracted Image 43](/images/image043.png)



---





Then choose tools and add the semantic model you created from earlier:



●  Choose to add a semantic view

●  Choose the database and schema where we created it (SI_EVENTS_HOL.PUBLIC)

●  Choose the Semantic View we created: MUSIC_FESTIVAL

●  Choose the warehouse: Snowflake_Intelligence_WH

●  Choose the Query Timeout: 600

●  Write a description: This is our festival data that we have stored in snowflake in tables

and structured data



Click Add the Semantic model

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 44](/images/image044.png)



---





After adding be sure to click save in the agent editor















Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 45](/images/image045.png)



![Extracted Image 46](/images/image046.png)



---

# Step 7: Test with Smart Agent

Let's go back to Snowflake Intelligence to see our new agent, which leverages our semantic

model. Either click Snowflake Intelligence or go to your Snowflake Intelligence tab and refresh

the page.



We can now see the Music Festival Agent.







Let's ask it a question: Show me the top 5 events by tickets sold.



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 47](/images/image047.png)



---





Fantastic, it gave us an answer with a chart of the top 5 events! I can open the SQL section and

see the join in the SQL.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 48](/images/image048.png)



---





We can ask another question: What is the ratio of ticket types purchased for Instead Fest?

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 49](/images/image049.png)



---





A third question I could ask is: Did any one customer go to multiple shows? This would utilize a

synonym we created (show) as well as utilize the relationship we created to the customers table:





These answers appear to be correct. If they were incorrect, the first step would be to review the

semantic model. This review would focus on verifying the accuracy of the defined relationships

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 50](/images/image050.png)



![Extracted Image 51](/images/image051.png)



---

and identifying any potential synonyms that could enhance the model's intelligence and

robustness.



Step 8: Create Search Service



We have document data that has been parsed and loaded into a table named `Contracts` from a

`Contracts.csv` file. To enable searching of this text data, we will create a search service. This

can be done by navigating to AI & ML, then Cortex Search, and following the wizard.











We can create it in our SNOWFLAKE_INTELLIGENCE.CONFIG database and schema, and

call it Festival_Contract_Search

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 52](/images/image052.png)



![Extracted Image 53](/images/image053.png)



---



Going to the next screen, it asks for the table that it wants to index. We will select a table that

we uploaded earlier. This is in the SI_EVENTS_HOL.PUBLIC and our table is called

CONTRACTS

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 54](/images/image054.png)



---



The next screen asks us to choose which column we want to be able to search. In our case, the

column name is TEXT. Go ahead and select that column from the list



Next, it is asking what attributes we want to bring in. We will choose both DOCUMENT_TITLE

and URL:



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 55](/images/image055.png)



![Extracted Image 56](/images/image056.png)



---



We will leave all columns on the next page selected:





As this is a demonstration with unchanging data, the chosen lag time is inconsequential.

Therefore, a 1-day lag can be applied.



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 57](/images/image057.png)



![Extracted Image 58](/images/image058.png)



---





Now our Search Service is created:







NOTE:

If your search service hangs in ‘Initialize’ for more than a few minutes, it might have failed. This

is going to be fixed in the UI in the future. However, right now you can run: DESC CORTEX
; and look at the indexing_error column,

SEARCH SERVICE FESTIVAL_CONTRACT_SEARCH

chances are it is a missing permission on an object such as a database, schema, table, or

warehouse.



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 59](/images/image059.png)



![Extracted Image 60](/images/image060.png)



---

# Step 9: Add to Agent

We will reuse the previously created "Music Festival Agent" and integrate the Search Service

we built into it. To do this, select the existing agent and then go to edit and proceed to add the

Search Service.

Then choose Tools and add the Festival Contract Search Cortex search agent you created.

Choose the URL and Document Title as shown below:



We will then add the search service by selecting where we created it, which was in

SNOWFLAKE_INTELLIGENCE.CONFIG we will call it Festival Contract Documents, and make

sure we define the URL column in our search service, which is called URL:



The service needs to be active before it can function, which will take a few minutes. Completion

is indicated when the Serving State shows as ACTIVE.



NOTE:

If your search service hangs in ‘Initialize’ for more than a few minutes, it might have failed. This

is going to be fixed in the UI in the future. However, right now you can run: DESC CORTEX
; and look at the indexing_error column,

SEARCH SERVICE FESTIVAL_CONTRACT_SEARCH

chances are it is a missing permission on an object such as a database, schema, table, or

warehouse.

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 61](/images/image061.png)



---





Make sure to save the agent after updating it with the new cortex search service:



Step 10: Test with Updated Agent

Let's go back to Snowflake Intelligence and make sure our new search service is available to

query, and then



Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 62](/images/image062.png)



![Extracted Image 63](/images/image063.png)



---







Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 64](/images/image064.png)



![Extracted Image 65](/images/image065.png)



---

Now that we see our Snowflake Data there, we know it will utilize our search service we created.

Let's ask it a question:

What is the cancellation policy for the band Algorhythms?



Notice that no SQL is generated or written, as it is using our search service. It gives us the

answer and the source of the document from which this information came.



Step 11: Review

This lab explored Snowflake Intelligence and its applications. Snowflake Intelligence enables

analysts to efficiently query Snowflake data by leveraging a semantic model or the Cortex

search service for data indexing.



Our steps were:

1.  Setup metadata for Snowflake Intelligence (this part will go away in the future)

2.  Create a dumb agent that just used Claude with no Snowflake data

3.  Created a Semantic Model

4.  Created a new agent to utilize the new semantic model and Snowflake Data

5.  Created a cortex search service

6.  Updated our agent to utilize that search service

7.  Wrote prompts in Snowflake Intelligence that utilized our semantic model and/or our

search service to get data from our Snowflake instance



Customers can now easily build a chatbot-like interface for analysts and search their Snowflake

assets using simple wizards, requiring minimal coding. This eliminates the need for complex

Created by: SE Enablement (Dan Murphy)            July 2025


![Extracted Image 66](/images/image066.png)



---

custom Python scripts (though that remains an option), enabling faster value realization with

GenAI within Snowflake.

Step 12: Validate Using DORA

Congrats! You have completed the lab. Please run the following commands in Snowsight to

confirm your completion.

✅ Validate Agents were created

SQL

use database SNOWFLAKE_INTELLIGENCE;

use schema AGENTS;





desc AGENT snowflake_intelligence.agents."MUSIC_FESTIVAL_AGENT";



SELECT

util_db.public.se_grader(

step,

(actual = expected),

actual,

expected,

description

) AS graded_results

FROM (

SELECT

'SEDW30' AS step,

(

SELECT COUNT(*)

FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))

) AS actual,

1 AS expected,

'Agents created for Snowflake Intelligence' AS description);



✅ Validate YML and semantic layer were created

SQL

use database SNOWFLAKE_INTELLIGENCE;

use schema CONFIG;



SELECT

util_db.public.se_grader(

step,

(actual = expected),

Created by: SE Enablement (Dan Murphy)            July 2025


---

actual,

expected,

description

) AS graded_results

FROM

(

SELECT

'SEDW31' AS step,

(

SELECT COUNT(*)

FROM DIRECTORY(@semantic_models)

WHERE RELATIVE_PATH LIKE 'music_festival.yaml'

) AS actual,

1 AS expected,

'Semantic Model was created for Snowflake Intelligence' AS

description

);



✅ Validate Cortex Search Service Created

SQL

use database SNOWFLAKE_INTELLIGENCE;

use schema CONFIG;



SELECT

util_db.public.se_grader(

step,

(actual = expected),

actual,

expected,

description

) AS graded_results

FROM

(

SELECT

'SEDW32' AS step,

(

SELECT COUNT(*)

FROM INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES

where SERVICE_NAME='FESTIVAL_CONTRACT_SEARCH'

) AS actual,

1 AS expected,

Created by: SE Enablement (Dan Murphy)            July 2025


---

'Cortex Search Service Created for Snowflake Intelligence' AS

description

);



If all validations return ✅, you have completed the Snowflake Intelligence Lab 🎉



Step 13: Reset your default warehouse and Default

Role



We recommend resetting your default role and warehouse to `ACCOUNTADMIN`. While

not strictly necessary, this can help prevent issues in other labs.

Created by: SE Enablement (Dan Murphy)            July 2025
