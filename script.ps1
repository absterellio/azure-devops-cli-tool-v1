Write-Host "Azure CLI Tool" -ForegroundColor Green
$pat = Read-Host -Prompt "Please enter your personal access token"

# option to specify the name of a repository or line-seperated file of several repository names
$repoQueryChoice = Read-Host -Prompt "Enter '1' to input a repo name. Enter '2' to specify a file of repo names"

# some basic error handling
while($repoQueryChoice -ne 1 -and $repoQueryChoice -ne 2) {
        Write-Host "Invalid input. Please try again."
        $repoQueryChoice = Read-Host -Prompt "Enter '1' to input a repo name. Enter '2' to specify a file of repo names"
}

if($repoQueryChoice -eq 1) {
    $repoName = Read-Host -Prompt "Please enter the repo name you would like to query"
} elseif ($repoQueryChoice -eq 2) {
    $fileName = Read-Host -Prompt "Enter a text file to read from. (Note: Specify each repo you would like to query on a new line of the file)"
}

$location = Read-Host -Prompt "Please specify a path for the output csv file"

Write-Host "Please wait for the output to be generated." -ForegroundColor Green

$projectName = "ex-repoName"

# authenticate based on the PAT
echo $pat | az devops login --organization ex-projectLink

# set csv file headers
Set-Content -Path $location -Value '"PR Number","Date Closed","Repo Name","Created By","Reviewers","Work Item Id"'

# get the repo names we want to query as input from user
if($repoQueryChoice -eq 2) {
    $repoNames = Get-Content $fileName
} else {
    $repoNames = $repoName
}

# for each repo, get pull request data
foreach ($repo in $repoNames) {

    # grab the completed PR's that went into the specified branch for this repo
    $prListObj = az repos pr list --project $projectName --repository $repo --status completed --target-branch ex-main --include-links | ConvertFrom-Json 

    foreach ($pr in $prListObj) {
        $prNumber = $pr.pullRequestId
        # list linked work items for this pull request
        $workItem = (az repos pr work-item list --id $pr.pullRequestId) | ConvertFrom-Json
        $workItemId = $workItem.id
        $createdBy = $pr.createdBy.displayName
        $reviewedBy = $pr.reviewers.displayName
        $date = $pr.closedDate

        # if the reviewer is part of a group, display the approver as well as group
        if($reviewedBy[1]) {
            $reviewedByString = "$($reviewedBy[1]) on behalf of $($reviewedBy[0])"
        } else {
            $reviewedByString = $reviewedBy[0]
        }

        # output each pr into the csv file
        Add-Content -Path $location -Value "$prNumber,$date,$repo,$createdBy,$reviewedByString,$workItemId"
    }
}

Write-Host "Please check $($location) for the generated report." -ForegroundColor Green
