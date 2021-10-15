
IF exist %1 IF not defined force (
    CALL run_error File exists: %1
)
