# DBT python project

- compute: databricks
- dbt packages: dbt-core(1.12.5), dbt-databricks (1.10.9)
- IDE: vscode
- extensions: DBT power user
- python: 3.12.13

### Project details 

A simple project medallion architecture loading and transforming small set of sales data using awesome dbt. The project exercises below features for learning:- 
- dbt tests
- dbt seeds
- dbt snapshots
- dbt macros
- config level precedences

#### important configs for project
- models are brought into bronze as it is to keep raw copy for reference
- model files are in jinja-sql format
- YAML filea are in jinja-yml format
