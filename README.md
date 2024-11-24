# Project Description

The included SQL script aims to answer business questions from the Northwind Traders database, a database of customer, order, product and employee data for a wholesale gourmet food company called Northwind Traders.

### The aim of the project was to ask questions and use the data to find answers related to the following themes:

1. Evaluating employee performance to boost productivity,
2. Understanding product sales and category performance to optimize inventory and marketing strategies.
3. Analyzing sales growth to identify trends, monitor company progress, and make more accurate forecast.
4. Evaluating customer purchase behavior to target high-value customers with promotional incentives

### The following questions related to these themes are answered in the script:
1. **Employee performance**
    1. Which employees have performed the best in terms of sales?
2. **Product sales and category performance**
    1. Which products and categories are sold most often? 
    2. Which products generate the most revenue?
3. ***Sales trends**
    1. Which periods of the year account for the highest and lowest revenue?
4. **Customer purchase behavior**
    1. Which products are commonly bought together? 
    2. Which customers return most often?
    3. What is the average number of items per order?

## Database Schema

![Alt text](https://github.com/pthom/northwind_psql/raw/master/ER.png "Northwind Diagram")


<!-- GETTING STARTED -->
# Getting Started

The SQL script was written based on the PostgreSQL version of the Northwind Traders database.

You will need to have PostgreSQL installed on your local machine.

You will also need to download and populate the Northwind Traders database locally.

The Northwind Traders database is available on [Github](https://github.com/pthom/northwind_psql/tree/master) and there are instructions for downloading and installing both PostgreSQL and the database [here](https://www.dataquest.io/blog/install-postgresql-14-7-on-windows-10/)

### Prerequisites

Once you have downloaded and installed PostgreSQL and poopulated the Northwind Traders database locally, you will need to choose a program to open and view the database tables and run the SQL script from this repository.

I used DBeaver for my database management and script writing, but other options include JupyterLab, BeeKeeper Studio, etc.

DBeaver is available for download, with installation instrcutions, [here](https://dbeaver.io/).

<!-- USAGE EXAMPLES -->
# Usage

The SQL script contains multiple queries. 

It is commented to indicate which queries are useful to answer each question (Q1, Q2, etc.). 

Queries can be run individually in a database tool, such as DBeaver, by dragging and selecting an individual entire query before executing. Multiple queries can not be run together.

<!-- ROADMAP -->
# Roadmap
Questions answered in the current script:
- [x] Q1) Which employees have performed the best in terms of sales?
- [x] Q2) Which products and categories are sold most often? 
- [x] Q3) Which products generate the most revenue?
- [x] Q4) Which periods of the year account for the highest and lowest revenu
- [x] Q5) Which products are commonly bought together? 
- [x] Q6) Which customers return most often?
- [x] Q7) What is the average number of items per order?

Questions for future updates:
- [] Q8) What are the most common products in the Top 20 orders by value?
- [] Q9) What is the average length of time between a customer placing an order and the ship date?

<!-- LICENSE -->
# License

Distributed under the MIT License. See `LICENSE.txt` for more information.




