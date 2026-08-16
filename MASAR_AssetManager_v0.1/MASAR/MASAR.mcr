macroScript MASAR
    category:"MASAR"
    internalCategory:"MASAR"
    tooltip:"Open MASAR - Asset Manager for 3ds Max"
    buttonText:"MASAR"
(
    on execute do
    (
        global MASAR_Native_Floater

        -- Single instance: the Native script clears the global reference when the window closes.
        if MASAR_Native_Floater != undefined then
        (
            try
            (
                if MASAR_Native_Floater.placementName == #minimized do
                    MASAR_Native_Floater.placementName = #normal
            ) catch()
            try(MASAR_Native_Floater.visible = true)catch()
            try(setFocus MASAR_Native_Floater)catch()
            return()
        )

        local f = pathConfig.appendPath (pathConfig.appendPath (getDir #userScripts) "MASAR") "MASAR_Native.ms"
        if doesFileExist f then
        (
            try(fileIn f)catch
            (
                local err = getCurrentException()
                messageBox (("MASAR could not be opened.\n\n" + (err as string))) title:"MASAR - Open Error"
            )
        )
        else
        (
            messageBox ("MASAR is not installed correctly.\n\nMissing file:\n" + f) title:"MASAR"
        )
    )
)
