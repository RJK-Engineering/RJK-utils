
IF EXIST %1 IF NOT DEFINED force (
    CALL run_error File exists: %1
)
