# Snowflake Intelligence HOL
**Utilize Agentic AI aginst your Snowflake data and Unstructured Data**

Snowflake Intelligence, a new application, empowers users to create and interact with data agents. These agents can access data from platforms like Snowflake and Salesforce to generate visualizations, create simple applications, and facilitate action on insights. Powered by Cortex LLM functions, Analyst, and Search, Snowflake Intelligence offers a curated, enterprise-ready application experience.

The ideal customer for a Snowflake Intelligence user is a business user, such as a sales rep, executive, or marketing manager, who is looking for insights and to take action based on data in their organization. Traditionally, they would have relied on BI applications or manually navigated file search (like SharePoint and Google Drive) and taken manual actions that can now be enhanced and automated with data agents.

> Snowflake Intelligence is currently under development. While some workflows in this lab may evolve as we approach production and refine our strategy, the foundational elements like semantic models, agents, and search services will persist. This lab will be updated periodically to reflect the product's progress. It represents the state of Snowflake Intelligence leading up to Summit 2025, as we aimed to provide this training beforehand.

---

## 🎬 Lab Overview Video
Watch the [X-minute Lab Overview Video](overview.mp4) for a detailed walkthrough of key lab phases.

---

## 🛠️ Hands-On Lab Overview

In this hands-on lab, you'll step into the shoes of **a Snowflake Developer** tasked with **creating a new agent for Snowflake Intelligence**.

### 📋 What You’ll Do:
This lab explores accessing festival data (ticket sales, customer details, events) and a parsed result of multiple bands' contract information. We'll join these datasets and build a semantic model using synonyms and defining relationships among the tables. This model will then be used in a prompt to retrieve data from Snowflake for end users via a simple chat-like interface. Consequently, users can obtain answers and data visualizations without needing SQL knowledge, understanding unstructured data queries, or data modeling concepts.

- **Ingest data into a database** 
- **Create a simple agent** 
- **Create a semantic view** 
- **Create a smarter agent using the semantic layer**: 
- **Create a search service**: 
- **Update the smart agent to also use the search service**: 
- **Utilize Snowflake Intelligence**: 



### ⏲️ Estimated Lab Timeline

Provide a brief agenda to help SEs understand pacing:

- **Phase 1 (Env setup):** ~5 min
- **Phase 2 ([creating sematic and cortex search](/lab_instructions/readme.md)):** ~30 min
- **Phase 3 (Testing Results in Snowflake Intelligence):** ~10 min
  
---

## 📖 Table of Contents

- [Why this Matters](#-why-this-matters)
- [Suggested Discovery Questions](#-suggested-discovery-questions)
- [Repository Structure](#-repository-structure)
- [Prerequisites & Setup Details](#-prerequisites--setup-details)
- [Estimated Lab Timeline](#-estimated-lab-timeline)
- [Troubleshooting & FAQ](#%EF%B8%8F-troubleshooting--faq)
- [Cleanup & Cost-Stewardship Procedures](#-cleanup--cost-stewardship-procedures)
- [Links to Internal Resources & Helpful Documents](#-links-to-internal-resources--helpful-documents)

---

## 📌 Why this Matters

  * **Self-serve data exploration:** Create charts and get instant answers using natural language. With an intuitive interface powered by agentic AI, enable teams to discover trends and analyze data without technical expertise or waiting for custom dashboards.
  * **Democratize intelligence:** Access and analyze thousands of data sources simultaneously, going beyond basic AI tools that only handle single documents.
  * **Comprehensive integration:** Seamlessly analyze structured and unstructured data together. Connect insights from spreadsheets, documents, images, and databases simultaneously.
  * **Automatic security:** Existing Snowflake security controls, including role-based access and data masking, automatically apply to all AI interactions and conversations.

---

## ❓ Suggested Discovery Questions

Provide **5 to 6 open-ended questions** for customer conversations related to this HOL.

- "How are you currently handling creating agentic AI solutions that search both structured data and unstructured data?"
- "What metrics matter most when evaluating speed to solutions and easy access from multiple personas?"
- "Have you faced any security or compliance roadblocks with utilizeing LLMs and Agentic AI?"
- "How would you customize this pattern for your environment?"

---

## 📂 Repository Structure

```bash
├── README.md           # Main entry point
├── config             # Configuration for DORA and Grading
├── data               # Datasets (CSV, JSON) or external links
├── images             # Diagrams and visual assets
├── lab_instructions    # Step-by-step detailed instructions
│ ├── images            # images for lab walkthrough
└── troubleshooting    # Common issues and resolutions
```
---

## ✅ Prerequisites & Setup Details

Internally helpful setup requirements:

- **Knowledge prerequisites:** A basic understanding of LLMs and how you can utilize them. Basic Snowflake knowledge to move around the product as needed.
- **Account and entitlement checks:** This is listed in the [lab directions](/lab_instructions/readme.md)
- **Hardware/software:** All browsers, AWS accounts recommended due to the LLM availability

---

## ⚠️ Troubleshooting & FAQ

Common errors and resolutions:

**Issue:** Model registration network timeout  
**Cause:** Likely incorrect VPC endpoint configuration  
**Solution:** Verify correct VPC endpoint and security group settings in AWS, then reattempt the registration.

Provide internal Slack channels or support queue links.

---

## 🧹 Cleanup & Cost-Stewardship Procedures

🗑 **Cleanup Instructions:**
- In the lab we setup the cortex search service to refresh daily. Go ahead and delete this cortex search service
- Drop the HOL database if no long desired
```sql
drop database SI_EVENTS_HOL
```


---

## 🔗 Links to Internal Resources & Helpful Documents

- [Snowflake Documentation](#)
- [Best Practices](#)
- [Quickstarts](#)
- [Internal Wiki & Guidelines](#)

---

## 👤 Author & Support

**Lab created by:** Dan Murphy – SE Enablement Senior Manager 
- **Created on:** July 28, 2025 | **Last updated:** July 28, 2025

💬 **Need Help or Have Feedback?**  
- Slack DM: [@dan.murphy](https://snowflake.enterprise.slack.com/team/WEJR92JS2)  
- Email: [dan.murphy@snowflake.com](mailto:dan.murphy@snowflake.com)

🌟 *We greatly value your feedback to continuously improve our HOL experiences!*
