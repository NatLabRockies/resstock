"""
Configuration schema for plot generation
----------------------------------------
Defines the Pydantic models for validating plot configuration
"""
from typing import Dict, List, Optional, Union, Any
from pathlib import Path
import yaml
from pydantic import BaseModel, Field
from enum import Enum

class ComparisonTypes(str, Enum):
    """Different interpretations of results columns."""
    absolute = "absolute"  # raw values
    savings = "savings"  # pre-aggregated mean across simulation rows
    percent_savings = "percent_savings"  # percentage savings compared to baseline

class VizType(str, Enum):
    """Supported chart templates."""
    bar = "bar"
    box = "box"
    hist = "histogram"

class QuantityGroup(BaseModel):
    """Definition of a quantity group with constituents and sum"""
    name: str = Field(description="Name of the quantity group")
    constituents: List[str] = Field(description="List of constituent columns")
    sum: Optional[str] = Field(None, description="Column name for the sum quantity")

class UpgradeInclusion(str, Enum):
    """Different ways to include a quantity in a plot."""
    all = "all"
    applied_only = "applied_only"

class VacancyInclusion(str, Enum):
    """Different ways to include a quantity in a plot."""
    all = "all"
    occupied_only = "occupied_only"


class WorkflowConfig(BaseModel):
    """Configuration for plot generation"""
    results_csvs_folder: str = Field(description="Path to folder containing results CSV files")
    output_dir: str = Field(description="Path to output directory")
    upgrades: List[int] = Field(description="List of upgrade indices to include")
    quantities: list[QuantityGroup] = Field(
        description="List of quantity groups to generate plots for"
    )
    group_by: List[str] = Field(description="List of grouping columns")
    visualization_types: list[VizType] = Field(description="List of visualization types to generate")
    comparison_types: list[ComparisonTypes] = Field(description="List of comparison types to generate")
    upgrade_inclusion: list[UpgradeInclusion] = Field(description="Upgrade inclusion type")
    vacancy_inclusion: list[VacancyInclusion] = Field(description="Vacancy inclusion type")
    
    @classmethod
    def from_yaml(cls, yaml_path: str) -> "WorkflowConfig":
        """
        Load configuration from a YAML file
        
        Args:
            yaml_path: Path to the YAML configuration file
            
        Returns:
            RunConfig instance
        """
        with open(yaml_path, 'r') as f:
            config_data = yaml.safe_load(f)
        
        return cls(**config_data)
