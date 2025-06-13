#!/usr/bin/env python3
"""Generate JSON schema from WorkflowConfig Pydantic model. The schema is used for static YAML validation
in VSCode and pre-commit hooks.
"""

import json
from pathlib import Path
from workflow_schema import WorkflowConfig

schema = WorkflowConfig.model_json_schema()
schema["additionalProperties"] = False
output_path = Path(__file__).parent / "workflow_schema.json"
output_path.write_text(json.dumps(schema, indent=2))
print(f"Wrote schema to {output_path}")
