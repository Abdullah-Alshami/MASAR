(
    local userScripts = getDir #userScripts
    local userMacros = getDir #userMacros
    local masarDir = pathConfig.appendPath userScripts "MASAR"
    local mcrFile = pathConfig.appendPath userMacros "MASAR.mcr"
    local nativeFile = pathConfig.appendPath masarDir "MASAR_Native.ms"
    local marker = pathConfig.appendPath masarDir ".toolbar_installed_native_v50"

    makeDir masarDir all:true

    if doesFileExist mcrFile then
    (
        try(macros.load mcrFile)catch(try(fileIn mcrFile)catch())
    )

    if not doesFileExist marker then
    (
        local ok = false
        try
        (
            cui.addMacroButton "Main Toolbar" "MASAR" "MASAR"
            ok = true
        )
        catch
        (
            try
            (
                cui.createToolbar "MASAR"
                cui.addMacroButton "MASAR" "MASAR" "MASAR"
                cui.showToolbar "MASAR" true
                ok = true
            )
            catch(ok = false)
        )
        if ok then
        (
            try(cui.saveConfig())catch()
            try
            (
                local f = createFile marker
                close f
            )catch()
        )
    )

    if doesFileExist nativeFile then
    (
        try(fileIn nativeFile)catch
        (
            local err = getCurrentException()
            messageBox ("MASAR was installed, but could not be opened.\n\nMAXScript error:\n" + (err as string) + "\n\nFile:\n" + nativeFile) title:"MASAR - Open Error"
        )
    )
    else
    (
        messageBox ("MASAR installation failed.\n\nMissing file:\n" + nativeFile) title:"MASAR"
    )
)
