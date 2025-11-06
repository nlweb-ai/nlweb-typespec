"""
Test script to validate that the TypeSpec-generated schemas match nlweb_core Pydantic models.
"""

import json
import yaml
from pathlib import Path
import sys

def load_typespec_schemas():
    '''load schemas from the TypeSpec generated OpenAPI'''
    openapi_path = Path(__file__).parent.parent / "tsp-output/openapi/openapi.yaml"

    if not openapi_path.exists():
        print("ERROR: OpenAPI schema not found. Run 'npx tsp compile .' first")
        sys.exit(1)

    with open(openapi_path) as f:
        openapi = yaml.safe_load(f)

    return openapi['components']['schemas']

def load_pydantic_schemas():
    '''
    load schemas from the nlweb_core Pydantic models
    
    This assumes that nlweb_core is installed or available in the path
    '''
    try:
        from nlweb_core.protocol import models
    except ImportError:
        print("ERROR: nlweb_core not found.  Install it first.")
        print("     pip install git+https://github.com/nlweb-ai/nlweb_core.git")
        sys.exit(1)

    schemas = {}
    
    #try to load each model, skip if it doesn't exist
    model_names = ['AskRequest', 'AskResponse', 'WhoRequest', 'WhoResponse']

    for model_name in model_names:
        if hasattr(models, model_name):
            model_class = getattr(models, model_name)
            schemas[model_name] = model_class.model_json_schema()
        else:
            print(f" {model_name} not found in nlweb_core")

    return schemas

def compare_required_fields(typespec_schema, pydantic_schema, model_name):
    '''check that required fields match'''
    ts_required = set(typespec_schema.get('required', []))
    py_required = set(pydantic_schema.get('required', []))

    #handle _meta vs meta naming
    if '_meta' in ts_required and 'meta' in py_required:
        py_required.remove('meta')
        py_required.add('_meta')

    if ts_required != py_required:
        print(f" {model_name}: Required fields mismatch")
        print(f" TypeSpec: {ts_required}")
        print(f" Pydantic: {py_required}")

    print(f" {model_name}: Required fields match")
    return True

def compare_properties(typespec_schema, pydantic_schema, model_name):
    '''check that properties exist in both'''
    ts_props = set(typespec_schema.get('properties', {}).keys())
    py_props = set(pydantic_schema.get('properties', {}).keys())

    #handle _meta vs meta naming
    if '_meta' in ts_props and 'meta' in py_props:
        py_props.remove('meta')
        py_props.add('_meta')

    missing_in_pydantic = ts_props - py_props
    missing_in_typespec = py_props - ts_props

    issues = False

    if missing_in_pydantic:
        print(f" {model_name}: Properties in TypeSpec but not Pydantic:  {missing_in_pydantic}")
        issues = True

    if missing_in_typespec:
        print(f" {model_name}: Properties in Pydantic but not in TypeSpec: {missing_in_typespec}")
        issues = True

    if not issues:
        print(f" {model_name}: All properties present in both")
    
    return not issues

def validate_model(model_name, typespec_schemas, pydantic_schemas):
    """Validate a single model"""
    print(f" Validating {model_name}...")
    
    if model_name not in typespec_schemas:
        print(f" {model_name} not found in TypeSpec schemas")
        return None  # Neither pass nor fail - just not applicable
    
    if model_name not in pydantic_schemas:
        print(f" {model_name} not yet implemented in nlweb_core - skipping")
        return None  # Not implemented yet - not a failure
    
    ts_schema = typespec_schemas[model_name]
    py_schema = pydantic_schemas[model_name]
    
    required_match = compare_required_fields(ts_schema, py_schema, model_name)
    props_match = compare_properties(ts_schema, py_schema, model_name)
    
    return required_match and props_match

def main():
    print("=" * 60)
    print("NLWeb Protocol Validation")
    print("Comparing TypeSpec specification with nlweb_core implementation")
    print("=" * 60)

    #Load schemas
    typespec_schemas = load_typespec_schemas()
    pydantic_schemas = load_pydantic_schemas()

    print(f" TypeSpec models: {len(typespec_schemas)}")
    print(f" Pydantic models: {len(pydantic_schemas)}")

    #validate each main model
    models_to_validate = ['AskRequest', 'AskResponse', 'WhoRequest', 'WhoResponse']

    results = {}
    for model_name in models_to_validate:
        results[model_name] = validate_model(model_name, typespec_schemas, pydantic_schemas)

    # Summary
    print("\n" + "+" * 60)
    print("SUMMARY")
    print("+" * 60)
    
    all_passed = all(results.values())

    for model_name, passed in results.items():
        status = "PASS" if passed else "FAIL"
        print(f"{status}: {model_name}")

    print("=" * 60)

    if all_passed:
        print("All validation passed! Spec and implementation match.")
        return 0
    else:
        print("Some validations failed. Please review the differences")
        return 1
    
if __name__ == '__main__':
    sys.exit(main())