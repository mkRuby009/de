# DBT python project

- compute: databricks
- dbt packages: dbt-core(1.12.5), dbt-databricks (1.10.9)
- IDE: vscode
- extensions: DBT power user
- python: 3.12.13

### Project details 

A simple project medallion architecture loading and transforming small set of sales data using awesome dbt.   
The project exercises below high-level features for learning (besides many other cool concepts):-   
- concepts: models, materializations, sources, references
- dbt seeds
- dbt snapshots
- dbt macros
- dbt tests
- dbt project profiles 
- dbt version controil (CI/CD deployment + profiles.yml)
- jinja templating
- dbt docs

#### Important configs for project
- models are brought into bronze as it is to keep raw copy for reference
- model files are in jinja-sql format
- YAML files are in jinja-yml format
