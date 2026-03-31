"""
Structured job postings and candidate profiles.
"""

from __future__ import annotations
from typing import Any, Dict, List, Optional
from pydantic import BaseModel

class JobPosting(BaseModel):
    title: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    salary: Optional[str] = None
    description: Optional[str] = None
    skills: Optional[List[str]] = None
    seniority: Optional[str] = None
    contract_type: Optional[str] = None
    metadata: Dict[str, Any] = {}

class CandidateProfile(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    skills: Optional[List[str]] = None
    experience: Optional[List[str]] = None
    education: Optional[List[str]] = None
    languages: Optional[List[str]] = None
    metadata: Dict[str, Any] = {}
