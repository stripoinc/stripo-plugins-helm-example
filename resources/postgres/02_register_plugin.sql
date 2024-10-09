INSERT INTO plugins (
    name,
    plugin_id,
    secret_key,
    status,
    config,
    subscription_type,
    sub_domain
) VALUES (
    'demoplugin',
    '7a4b7b4092e011eba8b30242ac130004',
    'e55c869d9e2846879c2e8eba1bf1b41b',
    'ACTIVE',
    '{"theme":{"type":"CUSTOM","params":{"primary-color":"#32cb4b","secondary-color":"#ffffff","border-radius-base":"17px","customFontLink":"","font-size":"14px","font-family":"-apple-system,BlinkMacSystemFont,\"SegoeUI\",Oxygen-Sans,Ubuntu,Cantarell,\"HelveticaNeue\",sans-serif","option-panel-background-color":"#f6f6f6","default-font-color":"#555555","panels-border-color":"#dddddd"},"removePluginBranding":true},"imageGallery":{"type":"PLUGIN","tabs":[{"label":{"en":"Email"},"key":"email_${emailId}"}],"maxFileSizeInKBytes":2048,"imagesBankEnabled":false,"imagesBankLabel":{"en":"Stock"},"pexelsEnabled":false,"pixabayEnabled":false,"iconFinderEnabled":false,"imageSearchEnabled":false,"iconSearchEnabled":false,"skipChunkedTransferEncoding":true},"blocksLibrary":{"enabled":true,"tabs":[{"viewOrder":0,"label":{"en":"Email"},"key":"email_${emailId}"}],"view":"FULL_WIDTH"},"baseBlocks":{"imageEnabled":true,"textEnabled":true,"buttonEnabled":true,"spacerEnabled":true,"videoEnabled":true,"socialNetEnabled":true,"bannerEnabled":true,"menuEnabled":true,"htmlEnabled":true,"timerEnabled":true,"ampCarouselEnabled":true,"ampAccordionEnabled":true,"ampFormControlsEnabled":true},"blockControls":{"blockVisibilityEnabled":true,"mobileIndentPluginEnabled":true,"mobileInversionEnabled":true,"mobileAlignmentEnabled":true,"stripePaddingEnabled":true,"containerBackgroundEnabled":true,"structureBackgroundImageEnabled":true,"containerBackgroundImageEnabled":true,"dynamicStructuresEnabled":true,"imageSrcLinkEnabled":true,"ampVisibilityEnabled":true,"smartBlocksEnabled":true,"imageEditorPluginEnabled":true,"synchronizableModulesEnabled":false,"rolloverEffectEnabled":true},"permissionsApi":{},"mergeTagsEnabled":true,"specialLinksEnabled":false,"customFontsEnabled":true,"ownControls":true,"autoSaveApi":{"enabled":false,"url":"","username":"username","password":"password"},"autoSaveApiV2":{"enabled":false,"url":"","username":"username","password":"password"},"autoSaveEnabled":true,"undoEnabled":true,"versionHistoryEnabled":true,"ai":{"openAiApiKey":"","textBlockAiEnabled":false,"smartModuleAiEnabled":false}}',
    'ENTERPRISE',
    'sub');
