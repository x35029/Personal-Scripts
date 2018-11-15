    Param
    (
        [Parameter(Mandatory=$true, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateSet("start", "shutdown", "save")]
        $action
    )

    $action
    
    switch ($action) {
        START {
            write-host "Action $action"
            write-host "outralinha $_"
        }

    }



    function test {
       switch ($action) {
        START {
            write-host "Action func $action"
            write-host "outralinha func $_"
        }

    }
    }
    test 