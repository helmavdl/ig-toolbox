# Handles:
# - A Bundle with .entry[] where some entries have .resource.resourceType == "OperationOutcome"
# - A single top-level OperationOutcome (resourceType == "OperationOutcome")
#
# Non-OperationOutcome resources pass through unchanged.

def is_suppressed(issue):
  # Condition 1: informational issues
  (issue.severity == "information" and issue.code == "informational") or
  # Condition 2: TerminologyEngine issues
  (issue.severity == "information" and issue.code == "invalid" and
   any(issue.extension[]?; .url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-issue-source" and .valueString == "TerminologyEngine")) or
  # Condition 3: InstanceValidator Reference_REF_MultipleMatches with nictiz.nl
  (issue.severity == "warning" and issue.code == "structure" and
   any(issue.extension[]?; .url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-issue-source" and .valueString == "InstanceValidator") and
   any(issue.extension[]?; .url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-message-id" and .valueCode == "Reference_REF_MultipleMatches") and
   (issue.details.text // "" | contains("nictiz.nl")))
;

def simplify_extensions(extensions):
  {
    line: (extensions[]? | select(.url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-issue-line") | .valueInteger),
    col: (extensions[]? | select(.url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-issue-col") | .valueInteger),
    source: (extensions[]? | select(.url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-issue-source") | .valueString),
    messageId: (extensions[]? | select(.url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-message-id") | .valueCode)
  }
;

# Core processor that accepts either:
# - an entry object containing .resource (OperationOutcome), or
# - a top-level OperationOutcome resource itself.
def process_oo($wrapper):
  # Normalize to the OO resource
  ($wrapper.resource? // $wrapper) as $res |

  # Filter out suppressed issues
  (($res.issue // []) | map(select(is_suppressed(.) | not))) as $remaining_issues |

  # Get file info and extract just the filename
  (first($res.extension[]? | select(.url == "http://hl7.org/fhir/StructureDefinition/operationoutcome-file") | .valueString) // null) as $full_path |
  ($full_path | if . then split("/") | last else null end) as $file |

  # Prepare a cleaned copy of the OO resource
  ($res
   | .text = null
   | .extension = ((.extension // []) | map(select(.url != "http://hl7.org/fhir/StructureDefinition/operationoutcome-file")))
   | .issue = ((.issue // []) | map(
       if .extension then
         .extension = simplify_extensions(.extension)
       else
         .
       end
     ))
  ) as $clean_res |

  # For bundles, return the cleaned entry; for single OO, return the cleaned resource
  (if $wrapper.resource? then ($wrapper | .resource = $clean_res) else $clean_res end) as $clean_wrapper |

  if ($remaining_issues | length) == 0 then
    {
      result: "OK",
      file: $file
    }
  else
    (any($remaining_issues[]?; .severity == "error")) as $has_errors |
    (any($remaining_issues[]?; .severity == "warning")) as $has_warnings |
    (all($remaining_issues[]?; .severity == "information")) as $all_info |
    {
      result: (
        if $has_errors then "ERROR"
        elif $has_warnings then "WARN"
        elif $all_info then "INFO"
        else "ISSUES_FOUND"
        end
      ),
      file: $file,
      resource: $clean_wrapper,
      unsuppressed_issues: ($remaining_issues | map(
        if .extension then
          .extension = simplify_extensions(.extension)
        else
          .
        end
      )),
      issue_count: ($remaining_issues | length),
      suppressed_count: (((($res.issue // []) | length)) - ($remaining_issues | length))
    }
  end
;

# Entry point: detect top-level type and dispatch
if .resourceType == "Bundle" then
  .entry[] |
  if .resource.resourceType == "OperationOutcome" then
    process_oo(.)
  else
    .
  end
elif .resourceType == "OperationOutcome" then
  process_oo(.)
else
  .
end
