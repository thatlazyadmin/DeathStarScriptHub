My stuff for managing Microsoft Sentinel.

Create-AnalyticRulesFromTemplates is a cmdlet that automates the creation of Analytic Rules in Microsoft Sentinel.
It creates the Analytic Rules based on the Analytic Rules Templates available in the Content Hub Solutions already installed in the Sentinel workspace. 
It's possible to filter out the Analytic Rules Templates to be considered by specifying the desired severities.
In an upcoming release, I'll add the possibility to specify in a CSV file which Analytic Rules Templates should (or should not) be considered.
The execution can be simulated, so that the script only logs what it would do but without doing any change to Sentinel.
The log file is created in the same local directory from where the script is launched. 

