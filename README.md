# Enterprise Retail Data Warehouse & BI Platform

## Project Overview
This project demonstrates the end-to-end architecture of an enterprise Business Intelligence platform. It encompasses the transformation of raw, unnormalized e-commerce data into a highly optimized OLTP relational database, and the subsequent development of an OLAP multidimensional cube for advanced analytical reporting.

### Technologies Used
* **Database:** Microsoft SQL Server, T-SQL
* **Analytical Engine:** SQL Server Analysis Services (SSAS), Multidimensional Expressions (MDX)
* **Architecture:** 3NF Normalization, Dimensional Modeling (Star Schema)

---

## Part 1: Relational Database Architecture (OLTP)
The initial dataset suffered from data redundancy, update anomalies, and limited scalability (e.g., repeating geographic attributes for every customer). 
* **Normalization:** The data was normalized to the Third Normal Form (3NF) to remove partial and transitive dependencies while balancing join-efficiency. 
* **Surrogate Keys:** Numeric surrogate keys (CityID, CustomerID, ProductGroupID) were introduced to improve storage efficiency and simplify joins.
* **Variant Architecture:** To resolve high null-density caused by sparse product attributes (size, color, leg length), a dedicated `Variant` table was engineered. This eliminated format inconsistencies and improved overall data quality.

## Part 2: Transactional Processing & ACID Compliance
To handle live order insertion, robust T-SQL Stored Procedures (`prCreateOrderGroup`, `prCreateOrderItem`) were developed.
* **Atomicity:** Multi-step operations (validating products, inserting items, updating order totals) were wrapped in explicit transactions (`BEGIN TRAN` / `COMMIT`).
* **Error Handling:** Implemented `TRY/CATCH` blocks to safely handle runtime errors and constraint violations, triggering immediate `ROLLBACK` commands to prevent partial record creation and guarantee data consistency.

## Part 3: Dimensional Modeling & OLAP Cube (SSAS)
A Data Source View (DSV) was designed as a Star Schema to support analytical querying, keeping a strict separation between transactional and analytical workloads.
* **The Grain:** The central `OrdersFact` table is defined at the order-line level to capture precise quantity and line-item values.
* **Many-to-Many Relationships:** A core design challenge involved products belonging to multiple product groups. Bridge tables with composite primary keys were introduced to handle this Many-to-Many relationship inside the cube without duplicating underlying fact data.
* **Calculated Measures:** Developed custom MDX measures to track complex operational KPIs, including Percentage Cancelled by Cost, Sales Value Cancelled, and Unfulfilled Order Ratios.

## Repository Structure
* `/SQL_Scripts`: Contains the raw T-SQL scripts for schema creation, constraints, and transactional stored procedures.
* `/SSAS_BI_Platform`: Contains the Visual Studio Multidimensional Project files (Cubes, Dimensions, and Data Source Views).
