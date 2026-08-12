//
//  CCWeatherConfig.h
//  公共配置 - 偏好键名、主题枚举、默认值
//

#import <UIKit/UIKit.h>

#ifndef CCWeatherConfig_h
#define CCWeatherConfig_h

// 偏好存储域
#define CCW_PREF_DOMAIN @"com.axs.ccweatherenhanced"
#define CCW_NOTIFY_CHANGED @"com.axs.ccweatherenhanced.changed"

// ========== 外观 ==========
#define kCCWThemeIndex          @"themeIndex"           // NSInteger 0~7
#define kCCWBackgroundStyle     @"backgroundStyle"      // NSInteger 0=毛玻璃 1=半透明 2=实色
#define kCCWBackgroundColor     @"backgroundColor"      // NSDictionary {r,g,b,a}
#define kCCWCornerRadius        @"cornerRadius"         // CGFloat 0~40
#define kCCWModuleAlpha         @"moduleAlpha"          // CGFloat 0.2~1.0
#define kCCWBorderEnabled       @"borderEnabled"        // BOOL
#define kCCWBorderWidth         @"borderWidth"          // CGFloat 0~5
#define kCCWBorderColor         @"borderColor"          // NSDictionary
#define kCCWShadowEnabled       @"shadowEnabled"        // BOOL
#define kCCWShadowRadius        @"shadowRadius"         // CGFloat
#define kCCWShadowOpacity       @"shadowOpacity"        // CGFloat 0~1

// ========== 字体大小 ==========
#define kCCWWeatherIconSize     @"weatherIconSize"      // CGFloat 30~120
#define kCCWTempFontSize        @"tempFontSize"         // CGFloat 20~100
#define kCCWCityFontSize        @"cityFontSize"         // CGFloat 12~40
#define kCCWHourlyFontSize      @"hourlyFontSize"       // CGFloat 10~30

// ========== 字体颜色 ==========
#define kCCWTempColor           @"tempColor"            // NSDictionary
#define kCCWCityColor           @"cityColor"
#define kCCWStatusColor         @"statusColor"
#define kCCWHourlyColor         @"hourlyColor"
#define kCCWRainbowEnabled      @"rainbowEnabled"       // BOOL
#define kCCWRainbowAnimated     @"rainbowAnimated"      // BOOL
#define kCCWRainbowSpeed        @"rainbowSpeed"         // CGFloat 0.1~5.0
#define kCCWGradientDirection   @"gradientDirection"    // NSInteger 0=水平 1=垂直 2=对角

// ========== 模块尺寸 ==========
#define kCCWModuleSize          @"moduleSize"           // NSInteger 0=小2x2 1=横4x2 2=大4x4
#define kCCWDynamicSize         @"dynamicSize"          // BOOL

// ========== 天气内容 ==========
#define kCCWShowHighLow         @"showHighLow"          // BOOL
#define kCCWShowCondition       @"showCondition"
#define kCCWShowPrecipitation   @"showPrecipitation"
#define kCCWShowCity            @"showCity"
#define kCCWShowHourly          @"showHourly"
#define kCCWShow24Hour          @"show24Hour"
#define kCCWWeatherIconStyle    @"weatherIconStyle"     // NSInteger 0=彩色 1=单色 2=简约
#define kCCWTempUnit            @"tempUnit"             // NSInteger 0=摄氏 1=华氏
#define kCCWAutoLocation        @"autoLocation"         // BOOL
#define kCCWCustomCity          @"customCity"           // NSString
#define kCCWCustomLatitude      @"customLatitude"       // NSNumber
#define kCCWCustomLongitude     @"customLongitude"      // NSNumber
#define kCCWRefreshInterval     @"refreshInterval"      // NSInteger 分钟 5/15/30/60

// ========== 交互 ==========
#define kCCWSingleTapAction     @"singleTapAction"      // 0=展开收起 1=刷新 2=设置 3=切换主题 4=无
#define kCCWDoubleTapAction     @"doubleTapAction"
#define kCCWLongPressAction     @"longPressAction"
#define kCCWTwoFingerTapAction  @"twoFingerTapAction"
#define kCCWExpandedMode        @"expandedMode"         // BOOL 展开状态

// ========== 布局 ==========
#define kCCWContentSpacing      @"contentSpacing"       // CGFloat
#define kCCWContentAlignment    @"contentAlignment"     // 0=左 1=中 2=右

// ========== 高级 ==========
#define kCCWAnimationEnabled    @"animationEnabled"     // BOOL
#define kCCWDebugLog            @"debugLog"             // BOOL

// 主题枚举
typedef NS_ENUM(NSInteger, CCWTheme) {
    CCWThemeSystem = 0,      // 跟随系统
    CCWThemeDark,            // 深色
    CCWThemeLight,           // 浅色
    CCWThemeOcean,           // 海洋蓝
    CCWThemeSunset,          // 日落橙
    CCWThemeForest,          // 森林绿
    CCWThemePurple,          // 梦幻紫
    CCWThemeMonochrome,      // 黑白极简
};

// 背景样式
typedef NS_ENUM(NSInteger, CCWBackgroundStyle) {
    CCWBackgroundStyleGlass = 0,
    CCWBackgroundStyleTranslucent,
    CCWBackgroundStyleSolid,
};

// 模块尺寸
typedef NS_ENUM(NSInteger, CCWModuleSize) {
    CCWModuleSizeSmall = 0,    // 2x2
    CCWModuleSizeLandscape,    // 4x2
    CCWModuleSizeLarge,        // 4x4
};

// 交互动作
typedef NS_ENUM(NSInteger, CCWTapAction) {
    CCWTapActionToggle = 0,
    CCWTapActionRefresh,
    CCWTapActionSettings,
    CCWTapActionSwitchTheme,
    CCWTapActionNone,
};

// 渐变方向
typedef NS_ENUM(NSInteger, CCWGradientDirection) {
    CCWGradientHorizontal = 0,
    CCWGradientVertical,
    CCWGradientDiagonal,
};

#endif /* CCWeatherConfig_h */
