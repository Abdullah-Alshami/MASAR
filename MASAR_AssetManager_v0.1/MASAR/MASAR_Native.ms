/*
    MASAR - Asset Manager for 3ds Max
    Native MAXScript Edition v50

    Design goals:
    - Pure MAXScript UI/runtime for maximum 3ds Max compatibility.
    - No Python, PySide, Qt, or .NET controls.
    - One compact, polished window.
    - English/Arabic layouts are mirrored manually.
    - All shared state is global to avoid MAXScript rollout-scope/thunk errors.
*/

global MASAR_Native_Floater
global MASAR_Native_SettingsFloater
global MASAR_Native_Rollout = undefined
global MASAR_Native_SettingsRollout = undefined

global MASAR_Native_Assets = #()
global MASAR_Native_Filtered = #()
global MASAR_Native_Selected = 0
global MASAR_Native_DataDir = ((getDir #userScripts) + "\\MASAR")
global MASAR_Native_SettingsFile = (MASAR_Native_DataDir + "\\settings.ini")

-- Single-instance lifecycle is controlled by MASAR.mcr.
-- Do not destroy an already-open MASAR window when the macro is clicked again.

fn masarBringToFront =
(
    if MASAR_Native_Floater == undefined then return false
    local ok = false
    try
    (
        if MASAR_Native_Floater.placementName == #minimized do MASAR_Native_Floater.placementName = #normal
    ) catch()
    try(MASAR_Native_Floater.visible = true)catch()
    try(setFocus MASAR_Native_Floater; ok = true)catch()
    ok
)

fn masarEnsureDir =
(
    try(makeDir MASAR_Native_DataDir all:true)catch()
)

fn masarGetSetting key defaultValue =
(
    masarEnsureDir()
    local v = ""
    try(v = getINISetting MASAR_Native_SettingsFile "Settings" key)catch(v="")
    if v == "" then defaultValue else v
)

fn masarSetSetting key value =
(
    masarEnsureDir()
    try(setINISetting MASAR_Native_SettingsFile "Settings" key (value as string))catch()
)

fn masarIsArabic =
(
    (masarGetSetting "Language" "en") == "ar"
)

fn masarTr key =
(
    local ar = masarIsArabic()
    case key of
    (
        #title: "MASAR - Asset Manager for 3ds Max"
        #header: "MASAR - Asset Manager for 3ds Max"
        #by: "BY Abdullah Alshami"
        #subtitle: "Manual asset management"
        #settings: if ar then "الإعدادات" else "Settings"
        #language: if ar then "اللغة" else "Language"
        #save: if ar then "حفظ" else "Save"
        #close: if ar then "إغلاق" else "Close"
        #scan: if ar then "فحص الملفات" else "Scan Assets"
        #saveSelected: if ar then "حفظ المحدد" else "Save Selected"
        #saveAll: if ar then "حفظ الكل" else "Save All"
        #package: if ar then "حزمة المشروع" else "Package Project"
        #actions: if ar then "الإجراءات" else "ACTIONS"
        #browse: if ar then "تصفح الملفات" else "BROWSE ASSETS"
        #details: if ar then "تفاصيل الملف" else "ASSET DETAILS"
        #assetActions: if ar then "إجراءات الملف" else "ASSET ACTIONS"
        #search: if ar then "بحث باسم الملف أو المسار..." else "Search asset name or path..."
        #all: if ar then "الكل" else "All"
        #status: if ar then "الحالة" else "Status"
        #type: if ar then "النوع" else "Type"
        #asset: if ar then "الملف" else "Asset"
        #source: if ar then "الموقع الأصلي" else "Original Location"
        #copyCol: if ar then "نسخة MASAR" else "MASAR Copy"
        #healthy: if ar then "سليم" else "Healthy"
        #missing: if ar then "مفقود" else "Missing"
        #saved: if ar then "محفوظ" else "Saved"
        #none: if ar then "غير متوفر" else "Not available"
        #ready: if ar then "جاهز" else "Ready"
        #openSource: if ar then "فتح مجلد المصدر" else "Open Source Folder"
        #openCopy: if ar then "فتح مجلد MASAR" else "Open MASAR Folder"
        #relink: if ar then "إعادة ربط" else "Relink Asset"
        #refresh: if ar then "تحديث" else "Refresh"
        #copy: if ar then "نسخ المسار" else "Copy Path"
        #scanComplete: if ar then "اكتمل الفحص" else "Asset scan complete"
        #pathCopied: if ar then "تم نسخ المسار إلى الحافظة." else "Path copied to clipboard."
        #saveOK: if ar then "تم حفظ الملف بنجاح." else "Asset saved successfully."
        #saveAllOK: if ar then "تم حفظ جميع الملفات." else "All assets processed."
        #packageOK: if ar then "تم إنشاء الحزمة بنجاح." else "Package created successfully."
        #packageFail: if ar then "فشل إنشاء الحزمة." else "Package creation failed."
        #select: if ar then "حدد ملفًا أولًا." else "Select an asset first."
        #saveScene: if ar then "احفظ مشهد 3ds Max أولًا." else "Save the 3ds Max scene first."
        #missingFile: if ar then "الملف الأصلي غير موجود." else "The original file is missing."
        #copyMissing: if ar then "نسخة MASAR غير موجودة." else "The MASAR copy does not exist."
        #relinkOK: if ar then "تمت إعادة الربط بنجاح." else "Asset relinked successfully."
        #relinkFail: if ar then "تعذر إعادة ربط هذا النوع تلقائيًا." else "This asset type could not be relinked automatically."
        #openFail: if ar then "تعذر فتح الملف." else "Could not open the file."
        #noSearch: if ar then "لا توجد نتائج." else "No matching assets."
        #english: "English"
        #arabic: "العربية"
        #assetCount: if ar then "الملفات" else "Assets"
        #savedCount: if ar then "محفوظ" else "Saved"
        #missingCount: if ar then "مفقود" else "Missing"
        #size: if ar then "الحجم" else "Size"
        #references: if ar then "المراجع" else "References"
        default: key as string
    )
)

fn masarProjectAssetsFolder =
(
    if maxFilePath == undefined or maxFilePath == "" then return ""
    local d = maxFilePath + "MASAR_Assets\\"
    try(makeDir d all:true)catch()
    d
)

fn masarFileExists p =
(
    p != undefined and p != "" and doesFileExist p
)

fn masarAssetFullPath au =
(
    local p = ""
    try
    (
        local f = au.GetFileName()
        local can = false
        try(can = au.CanGetFullFilePath f)catch(can=false)
        if can then try(p = au.GetFullFilePath())catch(p="")
        if p == "" then p = f
    ) catch()
    if p == undefined then "" else p as string
)

fn masarFileSize p =
(
    if not masarFileExists p then return "-"
    try
    (
        local n = getFileSize p
        if n < 1024 then ((n as string) + " B") else (((n as float / 1024.0) as string) + " KB")
    ) catch("-")
)

fn masarSavedCopyFor source =
(
    local folder = masarProjectAssetsFolder()
    if folder == "" or source == "" then return ""
    folder + (getFilenameFile source) + (getFilenameType source)
)

fn masarCopyAsset source =
(
    if not masarFileExists source then return false
    local dst = masarSavedCopyFor source
    if dst == "" then return false
    try
    (
        if doesFileExist dst then deleteFile dst
        copyFile source dst
        doesFileExist dst
    ) catch(false)
)

fn masarBuildAssets =
(
    local result = #()
    local n = 0
    try(n = AssetManager.GetNumAssets())catch(n=0)
    for i = 1 to n do
    (
        local au = undefined
        try(au = AssetManager.GetAssetByIndex i)catch(au=undefined)
        if au != undefined do
        (
            local id = ""
            local name = ""
            local full = ""
            local typ = #Other
            try(id = au.GetAssetId())catch()
            try(name = au.GetFileName())catch()
            try(full = masarAssetFullPath au)catch(full=name)
            try(typ = au.GetType())catch()
            if name != undefined and name != "" do
            (
                append result #(i, id as string, name as string, full as string, typ, masarFileExists full)
            )
        )
    )
    result
)

fn masarTypeText t =
(
    try(t as string)catch("Other")
)

fn masarAssetStatus a =
(
    if not a[6] then masarTr #missing
    else if masarFileExists (masarSavedCopyFor a[4]) then masarTr #saved
    else masarTr #healthy
)

fn masarMatchesFilter a =
(
    local search = ""
    local filter = "All"
    local filterIndex = 1
    try(search = MASAR_Native_Rollout.edSearch.text)catch()
    try(filter = MASAR_Native_Rollout.ddType.selected)catch()
    try(filterIndex = MASAR_Native_Rollout.ddType.selection)catch(filterIndex = 1)
    local hay = toLower ((a[3] as string) + " " + (a[4] as string))
    local okSearch = (search == "") or ((findString hay (toLower search)) != undefined)
    -- Item 1 is always "All/الكل". Technical asset types remain in English.
    local okType = (filterIndex == 1) or ((toLower (masarTypeText a[5])) == (toLower filter))
    okSearch and okType
)

fn masarApplyFilter =
(
    MASAR_Native_Filtered = #()
    for a in MASAR_Native_Assets do if masarMatchesFilter a do append MASAR_Native_Filtered a
    try
    (
        MASAR_Native_Rollout.lbAssets.items = for a in MASAR_Native_Filtered collect
        ((masarAssetStatus a) + "  |  " + masarTypeText a[5] + "  |  " + a[3] as string)
    ) catch()
    MASAR_Native_Selected = 0
    try(masarShowDetails 0)catch()
)

fn masarShowDetails idx =
(
    if idx < 1 or idx > MASAR_Native_Filtered.count then
    (
        try(MASAR_Native_Rollout.edDetails.text = masarTr #none)catch()
        return()
    )
    local a = MASAR_Native_Filtered[idx]
    local refs = 0
    try(refs = AssetManager.GetNumReference a[2])catch()
    local cp = masarSavedCopyFor a[4]
    local status = masarAssetStatus a
    local txt = (masarTr #asset) + ": " + a[3] + "\n" +
                (masarTr #type) + ": " + masarTypeText a[5] + "\n" +
                (masarTr #status) + ": " + status + "\n" +
                (masarTr #source) + ": " + a[4] + "\n" +
                (masarTr #copyCol) + ": " + (if cp == "" then masarTr #none else cp) + "\n" +
                (masarTr #size) + ": " + (masarFileSize a[4]) + "\n" +
                (masarTr #references) + ": " + (refs as string)
    try(MASAR_Native_Rollout.edDetails.text = txt)catch()
)

fn masarSelectedAsset =
(
    local s = 0
    try(s = MASAR_Native_Rollout.lbAssets.selection)catch(s=0)
    if s < 1 or s > MASAR_Native_Filtered.count then undefined else MASAR_Native_Filtered[s]
)

fn masarScan =
(
    MASAR_Native_Assets = masarBuildAssets()
    local total = MASAR_Native_Assets.count
    local saved = 0
    local missing = 0
    for a in MASAR_Native_Assets do
    (
        if not a[6] then missing += 1
        if masarFileExists (masarSavedCopyFor a[4]) then saved += 1
    )
    try
    (
        MASAR_Native_Rollout.lblAssets.text = ((masarTr #assetCount) + ": " + total as string)
        MASAR_Native_Rollout.lblSaved.text = ((masarTr #savedCount) + ": " + saved as string)
        MASAR_Native_Rollout.lblMissing.text = ((masarTr #missingCount) + ": " + missing as string)
        MASAR_Native_Rollout.lblStatus.text = (masarTr #scanComplete) + " — " + total as string
    ) catch()
    try
    (
        local types = #(masarTr #all)
        for a in MASAR_Native_Assets do
        (
            local t = masarTypeText a[5]
            if (findItem types t) == 0 do append types t
        )
        local oldSel = MASAR_Native_Rollout.ddType.selection
        MASAR_Native_Rollout.ddType.items = types
        MASAR_Native_Rollout.ddType.selection = if oldSel <= types.count then oldSel else 1
    ) catch()
    masarApplyFilter()
)

fn masarSaveSelected =
(
    local a = masarSelectedAsset()
    if a == undefined then (messageBox (masarTr #select) title:"MASAR"; return false)
    if not masarFileExists a[4] then (messageBox (masarTr #missingFile) title:"MASAR"; return false)
    local ok = masarCopyAsset a[4]
    if ok then
    (
        try(saveMaxFile maxFilePath quiet:true)catch()
        masarScan()
        messageBox (masarTr #saveOK) title:"MASAR"
    )
    else messageBox (if masarIsArabic() then "تعذر حفظ الملف." else "Could not save asset.") title:"MASAR"
    ok
)

fn masarSaveAll =
(
    if maxFilePath == undefined or maxFilePath == "" then (messageBox (masarTr #saveScene) title:"MASAR"; return false)
    local okCount = 0
    local badCount = 0
    for a in MASAR_Native_Assets do
    (
        if masarFileExists a[4] then (if masarCopyAsset a[4] then okCount += 1 else badCount += 1) else badCount += 1
    )
    try(saveMaxFile maxFilePath quiet:true)catch()
    masarScan()
    messageBox ((masarTr #saveAllOK) + "\n\n" + (okCount as string) + " " + (if masarIsArabic() then "محفوظ" else "saved") +
                "\n" + (badCount as string) + " " + (if masarIsArabic() then "مفقود/خطأ" else "missing/error")) title:"MASAR"
    true
)

fn masarOpenFolderForFile p =
(
    if p == undefined or p == "" or not doesFileExist p then return false
    local folder = getFilenamePath p
    if folder == undefined or folder == "" then return false
    try
    (
        -- Open Windows Explorer on the containing folder and select the asset.
        local args = "/select,\"" + p + "\""
        shellLaunch "explorer.exe" args
        true
    ) catch(false)
)

fn masarOpenSource =
(
    local a = masarSelectedAsset()
    if a == undefined then (messageBox (masarTr #select) title:"MASAR"; return false)
    if not masarFileExists a[4] then (messageBox (masarTr #missingFile) title:"MASAR"; return false)
    if masarOpenFolderForFile a[4] then true else (messageBox (masarTr #openFail) title:"MASAR"; false)
)

fn masarOpenCopy =
(
    local a = masarSelectedAsset()
    if a == undefined then (messageBox (masarTr #select) title:"MASAR"; return false)
    local p = masarSavedCopyFor a[4]
    if not masarFileExists p then (messageBox (masarTr #copyMissing) title:"MASAR"; return false)
    if masarOpenFolderForFile p then true else (messageBox (masarTr #openFail) title:"MASAR"; false)
)

fn masarCopyPath =
(
    local a = masarSelectedAsset()
    if a == undefined then (messageBox (masarTr #select) title:"MASAR"; return false)
    local rc = setclipboardText a[4]
    if rc == true then try(MASAR_Native_Rollout.lblStatus.text = masarTr #pathCopied)catch()
    rc
)

fn masarRelinkSelected =
(
    local a = masarSelectedAsset()
    if a == undefined then (messageBox (masarTr #select) title:"MASAR"; return false)
    local old = a[4]
    local newp = getOpenFileName caption:(masarTr #relink)
    if newp == undefined then return false
    local typ = a[5]
    local done = false

    if typ == #bitmap do
    (
        for bm in (getClassInstances BitmapTexture) do
        (
            try
            (
                local f = bm.filename as string
                local abs = f
                try(abs = pathConfig.convertPathToAbsolute f)catch()
                if (toLower f == toLower old) or (toLower abs == toLower old) do
                (
                    bm.filename = newp
                    done = true
                )
            ) catch()
        )
    )

    if typ == #xref do
    (
        try
        (
            local records = refs.getXRefFileRecords()
            for r in records do
            (
                local f = ""
                try(f = r.srcFileName as string)catch()
                if toLower f == toLower old do
                (
                    try
                    (
                        if objXRefMgr.SetRecordSrcFile r newp then done = true
                    )
                    catch(try(r.srcFileName = newp; done = true)catch())
                )
            )
            try(objXRefMgr.UpdateAllRecords())catch()
        ) catch()
    )

    if done then
    (
        try(saveMaxFile maxFilePath quiet:true)catch()
        masarScan()
        messageBox (masarTr #relinkOK) title:"MASAR"
        true
    )
    else
    (
        messageBox (masarTr #relinkFail) title:"MASAR"
        false
    )
)

fn masarPackage =
(
    if maxFilePath == undefined or maxFilePath == "" then (messageBox (masarTr #saveScene) title:"MASAR"; return false)
    local defaultOut = maxFilePath + "_Archive.zip"
    local out = getSaveFileName caption:(masarTr #package) filename:defaultOut types:"ZIP Archive (*.zip)|*.zip|"
    if out == undefined then return false
    if getFilenameType out == "" then out += ".zip"
    if doesFileExist out then deleteFile out
    local ok = false
    try(ok = archiveMAXFile out)catch(ok=false)
    if ok and doesFileExist out then
    (
        try(MASAR_Native_Rollout.lblStatus.text = masarTr #packageOK)catch()
        messageBox ((masarTr #package) + "\n\n" + out) title:"MASAR"
        true
    )
    else
    (
        try(MASAR_Native_Rollout.lblStatus.text = masarTr #packageFail)catch()
        messageBox (masarTr #packageFail) title:"MASAR"
        false
    )
)

fn masarApplyLayout =
(
    if MASAR_Native_Rollout == undefined then return()
    try
    (
        -- One fixed layout for both languages. This matches the former PySide order.
        -- Arabic changes only functional labels; it never changes control positions.
        MASAR_Native_Rollout.lblHeader.pos = [18,10]
        MASAR_Native_Rollout.lblHeader.align = #left
        MASAR_Native_Rollout.lblBy.pos = [20,32]
        MASAR_Native_Rollout.lblBy.align = #left
        MASAR_Native_Rollout.lblSubtitle.pos = [20,48]
        MASAR_Native_Rollout.lblSubtitle.align = #left
        MASAR_Native_Rollout.btnSettings.pos = [382,12]

        MASAR_Native_Rollout.lblAssets.pos = [28,82]
        MASAR_Native_Rollout.lblSaved.pos = [180,82]
        MASAR_Native_Rollout.lblMissing.pos = [332,82]

        MASAR_Native_Rollout.lblActions.pos = [18,118]
        MASAR_Native_Rollout.lblActions.align = #left
        MASAR_Native_Rollout.btnScan.pos = [18,140]
        MASAR_Native_Rollout.btnSaveSelected.pos = [18,176]
        MASAR_Native_Rollout.btnSaveAll.pos = [256,176]
        MASAR_Native_Rollout.btnPackage.pos = [18,212]

        MASAR_Native_Rollout.lblBrowse.pos = [18,250]
        MASAR_Native_Rollout.lblBrowse.align = #left
        MASAR_Native_Rollout.ddType.pos = [18,273]
        MASAR_Native_Rollout.edSearch.pos = [172,273]
        MASAR_Native_Rollout.lbAssets.pos = [18,303]

        MASAR_Native_Rollout.lblDetailsTitle.pos = [18,495]
        MASAR_Native_Rollout.lblDetailsTitle.align = #left
        MASAR_Native_Rollout.edDetails.pos = [18,518]

        MASAR_Native_Rollout.lblAssetActions.pos = [18,610]
        MASAR_Native_Rollout.lblAssetActions.align = #left
        MASAR_Native_Rollout.btnOpenSource.pos = [18,633]
        MASAR_Native_Rollout.btnOpenCopy.pos = [256,633]
        MASAR_Native_Rollout.btnRelink.pos = [18,667]
        MASAR_Native_Rollout.btnRefresh.pos = [256,667]
        MASAR_Native_Rollout.btnCopy.pos = [18,701]
        MASAR_Native_Rollout.lblStatus.pos = [18,735]
        MASAR_Native_Rollout.lblStatus.align = #left
    ) catch()
)

fn masarApplyLanguage =
(
    try
    (
        -- Language changes text only. The controls and callbacks stay identical.
        masarApplyLayout()
        MASAR_Native_Rollout.title = masarTr #title
        MASAR_Native_Rollout.lblHeader.text = masarTr #header
        MASAR_Native_Rollout.lblBy.text = masarTr #by
        MASAR_Native_Rollout.lblSubtitle.text = masarTr #subtitle
        MASAR_Native_Rollout.btnSettings.text = masarTr #settings
        MASAR_Native_Rollout.lblActions.text = masarTr #actions
        MASAR_Native_Rollout.btnScan.text = masarTr #scan
        MASAR_Native_Rollout.btnSaveSelected.text = masarTr #saveSelected
        MASAR_Native_Rollout.btnSaveAll.text = masarTr #saveAll
        MASAR_Native_Rollout.btnPackage.text = masarTr #package
        MASAR_Native_Rollout.lblBrowse.text = masarTr #browse
        MASAR_Native_Rollout.edSearch.text = ""
        MASAR_Native_Rollout.lblDetailsTitle.text = masarTr #details
        MASAR_Native_Rollout.lblAssetActions.text = masarTr #assetActions
        MASAR_Native_Rollout.btnOpenSource.text = masarTr #openSource
        MASAR_Native_Rollout.btnOpenCopy.text = masarTr #openCopy
        MASAR_Native_Rollout.btnRelink.text = masarTr #relink
        MASAR_Native_Rollout.btnRefresh.text = masarTr #refresh
        MASAR_Native_Rollout.btnCopy.text = masarTr #copy
        masarScan()
    ) catch()
)

fn masarSettings =
(
    try(closeRolloutFloater MASAR_Native_SettingsFloater)catch()
    MASAR_Native_SettingsFloater = newRolloutFloater (masarTr #settings) 360 155
    addRollout MASAR_Native_SettingsRollout MASAR_Native_SettingsFloater
)

-- Compact, polished native UI. 500 x 540 logical pixels.
rollout MASAR_Native_Rollout "MASAR - Asset Manager for 3ds Max" width:500 height:760
(
    label lblHeader "MASAR - Asset Manager for 3ds Max" pos:[18,10] width:330 height:22
    label lblBy "BY Abdullah Alshami" pos:[20,32] width:210 height:16
    label lblSubtitle "Manual asset management" pos:[20,48] width:270 height:16
    button btnSettings "Settings" pos:[382,12] width:100 height:30

    groupBox stats "" pos:[18,70] width:464 height:42
    label lblAssets "Assets: 0" pos:[28,82] width:140 height:20 align:#center
    label lblSaved "Saved: 0" pos:[180,82] width:140 height:20 align:#center
    label lblMissing "Missing: 0" pos:[332,82] width:140 height:20 align:#center

    label lblActions "ACTIONS" pos:[18,118] width:180 height:18
    button btnScan "Scan Assets" pos:[18,140] width:464 height:30
    button btnSaveSelected "Save Selected" pos:[18,176] width:226 height:30
    button btnSaveAll "Save All Assets" pos:[256,176] width:226 height:30
    button btnPackage "Package Project" pos:[18,212] width:464 height:30

    label lblBrowse "BROWSE ASSETS" pos:[18,250] width:180 height:18
    dropdownlist ddType "" pos:[18,273] width:146 height:24 items:#("All")
    edittext edSearch "" pos:[172,273] width:310 height:24
    listbox lbAssets items:#("Scan the scene to load assets") pos:[18,303] width:464 height:10

    label lblDetailsTitle "ASSET DETAILS" pos:[18,495] width:180 height:18
    edittext edDetails "Select an asset to view details." pos:[18,518] width:464 height:78 readOnly:true multiLine:true

    label lblAssetActions "ASSET ACTIONS" pos:[18,610] width:180 height:18
    button btnOpenSource "Open Source Folder" pos:[18,633] width:226 height:28
    button btnOpenCopy "Open MASAR Folder" pos:[256,633] width:226 height:28
    button btnRelink "Relink" pos:[18,667] width:226 height:28
    button btnRefresh "Refresh" pos:[256,667] width:226 height:28
    button btnCopy "Copy Path" pos:[18,701] width:464 height:28
    label lblStatus "Ready" pos:[18,735] width:464 height:16

    on MASAR_Native_Rollout open do masarApplyLanguage()
    on MASAR_Native_Rollout close do
    (
        -- Allow the toolbar macro to create a new instance after the user closes MASAR.
        MASAR_Native_Floater = undefined
        MASAR_Native_SettingsFloater = undefined
    )
    on btnScan pressed do masarScan()
    on btnSaveSelected pressed do masarSaveSelected()
    on btnSaveAll pressed do masarSaveAll()
    on btnPackage pressed do masarPackage()
    on btnOpenSource pressed do masarOpenSource()
    on btnOpenCopy pressed do masarOpenCopy()
    on btnRelink pressed do masarRelinkSelected()
    on btnRefresh pressed do masarScan()
    on btnCopy pressed do masarCopyPath()
    on btnSettings pressed do masarSettings()
    on edSearch changed txt do masarApplyFilter()
    on ddType selected i do masarApplyFilter()
    on lbAssets selected i do
    (
        MASAR_Native_Selected = i
        masarShowDetails i
    )
)

rollout MASAR_Native_SettingsRollout "Settings" width:340 height:120
(
    label lblLang "Language:" pos:[15,12] width:100 height:20
    dropdownlist lang "" pos:[120,10] width:200 height:24 items:#("English","العربية")
    button saveSettings "Save" pos:[70,60] width:90 height:28
    button cancelSettings "Cancel" pos:[180,60] width:90 height:28

    on MASAR_Native_SettingsRollout open do
    (
        lang.selection = if masarIsArabic() then 2 else 1
        lblLang.text = masarTr #language
        saveSettings.text = masarTr #save
        cancelSettings.text = masarTr #close
    )
    on saveSettings pressed do
    (
        masarSetSetting "Language" (if lang.selection == 2 then "ar" else "en")
        try(closeRolloutFloater MASAR_Native_SettingsFloater)catch()
        masarApplyLanguage()
    )
    on cancelSettings pressed do try(closeRolloutFloater MASAR_Native_SettingsFloater)catch()
)

MASAR_Native_Floater = newRolloutFloater (masarTr #title) 500 760
addRollout MASAR_Native_Rollout MASAR_Native_Floater
