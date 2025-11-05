# NLWeb Protocol TypeSpec Specification

This repository contains the formal TypeSpec specification for the NLWeb protocol, which defines a standardized interface for natural language interactions with web endpoints.

## What is NLWeb?

NLWeb provides two main endpoints:

- **Ask**: Query endpoints with natural language and receive structured responses
- **Who**: Discover which agents/tools can answer a given question

## Using This Specification

### For Python Developers

Use the companion [nlweb_core Python library](https://github.com/nlweb-ai/nlweb_core) which provides Pydantic models.

### For Other Languages

Generate types from the OpenAPI schema:

```bash
# View the generated schema
cat tsp-output/openapi/openapi.yaml

# Generate TypeScript types
npx openapi-typescript tsp-output/openapi/openapi.yaml -o nlweb-types.ts

# Generate Go types (example)
oapi-codegen -generate types -package nlweb tsp-output/openapi/openapi.yaml > nlweb.go
```

## Development

### Compile TypeSpec

```bash
npm install
npx tsp compile .
```

### View Generated Schemas

```bash
cat tsp-output/openapi/openapi.yaml
```

## Protocol Version

Current version: 0.5

## Links

- [Python Implementation](https://github.com/nlweb-ai/nlweb_core)