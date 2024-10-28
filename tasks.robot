*** Settings ***
Documentation       Template robot main suite.
Resource    ./Resources/Settings.robot
Library    Collections

*** Variables ***
${OUTPUT_DIR}    ./output
${CSVURL}    https://robotsparebinindustries.com/orders.csv
${CHROMEDRIVER_PATH}    /usr/local/bin/chromedriver
${InputCSVFilePath}    ./orders.csv
${ScreenShotPath}    ${OUTPUT_DIR}/Screenshot/
${InitialPDFPath}    ${OUTPUT_DIR}/PDFFiles/
${FinalArchivePath}    ${OUTPUT_DIR}/Archive/
${MediumDelay}    5s
${SmallDelay}    2s
${LongDelay}    10s
${RetryCount}    3

*** Tasks ***
Minimal task
    Log    Done.
Download orders file from website
    Download Orders

open website of robot
    open website

Read and Log CSV File Into Table
    ${table}=    Read Table From CSV    ${InputCSVFilePath}    headers=True
    Log Table    ${table}

Archive and Cleanup Files
    Create Directory    ${FinalArchivePath}
    Zip File of PDFFiles   ${InitialPDFPath}    ${FinalArchivePath}
    #Remove Temp PDF Directory    ${InitialPDFPath}    ${ScreenShotPath}




*** Keywords ***
open website
    # ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    # Call Method    ${chrome_options}    add_argument    --no-sandbox
    # Call Method    ${chrome_options}    add_argument    --headless
    # Open Browser    https://robotsparebinindustries.com/#/robot-order    Chrome    options=${chrome_options}    executable_path=${CHROMEDRIVER_PATH}
    Open Browser    https://robotsparebinindustries.com/#/robot-order    Chrome    
    Maximize Browser Window
    
    
    

Download Orders
    #Create Directory    ${OUTPUT_DIR}
    Download   ${CSVURL}    ${InputCSVFilePath}    overwrite=${True} 
    Create Directory    ${ScreenShotPath}
    Create Directory    ${InitialPDFPath}
    
    

Log Table
    [Arguments]    ${table}
    FOR    ${row}    IN    @{table}
        Fill Form    ${row}
    END
    Close Browser

Fill Form
    [Arguments]    ${row}
    Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Sleep    ${SmallDelay}
    Select From List By Index    //*[@id="head"]    ${row['Head']}
    Input Text    //form//div//input[@placeholder='Enter the part number for the legs' and @type='number']    ${row['Legs']}
    Input Text    name:address    ${row['Address']}
    Click Element    //input[@id="id-body-${row['Body']}"]
    Sleep    ${SmallDelay}

    FOR    ${Index}    IN RANGE    ${RetryCount}
        Scroll Element Into View    //*[@id="order"]
        Click Button    //*[@id="order"]
        Sleep    ${SmallDelay}
        Log    Attempt ${Index+1} to find the element
        # ${element_exists}=    Run Keyword And Return Status    Element Should Exist    //div[@class='alert alert-danger']    timeout=5s
        ${element_exists}=    Run Keyword And Return Status    Page Should Contain Element    //p[@class="badge badge-success"]    timeout=${MediumDelay}
        IF    ${element_exists}
            Log    Order placed successfully
            BREAK
        ELSE
            Log    error detected, retrying
            Sleep    ${SmallDelay}
            CONTINUE
        END
    END
    Log    Retry loop completed
    
    # Final check to ensure order was placed
    ${order_success}=    Run Keyword And Return Status    Page Should Contain Element    //p[@class="badge badge-success"]    timeout=5s
    Run Keyword If    ${order_success}    Log    Final check: Order successfully placed
    Run Keyword If    not ${order_success}    Fail    Order was not placed after ${RetryCount} attempts

    
    ${Order_Number}=     Get Text    //p[@class="badge badge-success"]
    Log    Order number detected ${Order_Number}
    ${CurrentScreenShot}=    Capture Page Screenshot    ${ScreenShotPath}${Order_Number}.png
    Wait Until Keyword Succeeds    5    1    File Should Exist    ${CurrentScreenShot}
    Sleep    ${SmallDelay}
    Create PDF With Screenshot    ${Order_Number}    ${CurrentScreenShot}
    Sleep    ${SmallDelay}
    Click Button    //*[@id="order-another"]
                                    
Create PDF With Screenshot
    [Arguments]    ${Order_Number}    ${CurrentScreenShot}
    OperatingSystem.Create File    ${InitialPDFPath}/${Order_Number}.pdf
    ${pdfFiles}=    Create List
    ...    ${CurrentScreenShot}  
    ${pdfFileName}    Get From List    ${pdfFiles}    0
    Log    Filename to be added ${pdfFileName}
    Add Files To Pdf    ${pdfFiles}    ${InitialPDFPath}/${Order_Number}.pdf
    Log    Screenshot saved as PDF: ${pdfFiles}

Zip File of PDFFiles
    [Arguments]    ${InitialPDFPath}    ${FinalArchivePath}
    Log    Merging files from path ${InitialPDFPath}
    Archive Folder With Zip    ${InitialPDFPath}    ${FinalArchivePath}/Merged.zip

# Remove Temp PDF Directory
#     [Arguments]    ${InitialPDFPath}    ${ScreenShotPath}
#     Remove Directory    ${InitialPDFPath}    recursive=True
#     Remove Directory    ${ScreenShotPath}    recursive=True
    



    