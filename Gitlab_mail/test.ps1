# https://mailtrap.io/blog/powershell-send-email/
# Bearer tocken
param (
    [Parameter(Mandatory = $False)]
    [string] $additionalCommentarty = "No additional commentaries added",

    [Int] $projectID = 000000,
    #[string[]] $list 
)


$Authorization = "Bearer token"

$Header = @{
    "authorization" = $Authorization
}

$getProjectJobsParameters = @{
    Method      = "GET"
    Uri         = "https://gitlab.com/api/v4/projects/$projectID/jobs"
    ContentType = "application/json"
    Headers     = $Header
}

$allProjectJobs = Invoke-RestMethod @GetProjectJobsParameters 
$lastJobId = $allProjectJobs.id[0]

/projects/:id/jobs/:job_id/trace

$getJobStatusParameters = @{
    Method      = "GET"
    Uri         = "https://gitlab.com/api/v4/projects/$projectID/jobs/$lastJobId"
    ContentType = "application/json"
    Headers     = $Header
}

$jobStatus = (Invoke-RestMethod @getJobStatusParameters ).status


##############################################
# Send Email via smtp.mailtrap.io SMTP server
##############################################
$SMTPHost = "smtp.mailtrap.io"
$SMTPPort = 587
$SMTPUsername = ""  
$SMTPPassword = "" 
$SMTPPasswordSecure = ConvertTo-SecureString -String $SMTPPassword -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SMTPUsername, $SMTPPasswordSecure

$list = @("sdsdsd1@gmail.com", "asasdasd@gmail.com")

#$From = "oleh.klymchuk@avenga.com"


Send-MailMessage -From "oleh.klymchuk@avenga.com" `
                 -To "sdsdsd1@gmail.com", "asasdasd@gmail.com" `
                 -Subject "Job Status $lastJobId" `
                 -Body "Job with ID: $lastJobId`nFinnished with status: $jobStatus`nDirect link to job: https://gitlab.com/api/v4/$projectID/jobs/$lastJobId `nAdditional commentary: $additionalCommentarty" `
                 -Credential $Credential `
                 -SmtpServer $SMTPHost `
                 -Port $SMTPPort
