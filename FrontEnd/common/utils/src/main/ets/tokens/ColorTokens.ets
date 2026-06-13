/**
 * MES 设计系统 — 色彩令牌
 * 基于 ui-ux-pro-max Data-Dense Dashboard 风格，适配项目蓝色品牌
 *
 * 三层架构：基础色板 → 语义令牌 → 组件令牌
 * 引用方式：import { Colors } from '@ohos/utils'
 */

// ============================================================
// 内部接口
// ============================================================

interface StatusColor {
  fg: string;
  bg: string;
}

interface RoleColor {
  avatar: string;
  badge: string;
  bg: string;
}

interface RoleBadgeColor {
  bg: string;
  fg: string;
}

// ============================================================
// 1. Primitive Tokens — 基础色板
// ============================================================

// Blue
const blue900 = '#0D47A1';
const blue800 = '#1155B7';
const blue700 = '#1565C0';
const blue500 = '#1890ff';
const blue50 = '#E3F2FD';

// Green
const green600 = '#4CAF50';
const green500 = '#52c41a';
const green50 = '#E8F5E9';

// Red
const red600 = '#F44336';
const red500 = '#f5222d';
const red50 = '#FFEBEE';

// Orange
const orange600 = '#FF9800';
const orange500 = '#faad14';
const orange400 = '#fa8c14';
const orange50 = '#FFF3E0';

// Purple
const purple600 = '#722ed1';
const purple50 = '#F3E5F5';

// Teal
const teal600 = '#00897B';
const teal500 = '#13c2c2';
const teal50 = '#E0F2F1';

// Gray
const gray900 = '#1A1A2E';
const gray700 = '#334155';
const gray600 = '#5A5A6E';
const gray500 = '#9A9AA8';
const gray400 = '#999999';
const gray200 = '#E8EBF0';
const gray100 = '#F5F7FA';
const gray50 = '#F8FAFC';
const white = '#FFFFFF';

// Chart colors (data visualization)
const chartBlue = '#1890ff';
const chartGreen = '#52c41a';
const chartOrange = '#faad14';
const chartRed = '#f5222d';
const chartPurple = '#722ed1';
const chartTeal = '#13c2c2';

// ============================================================
// 2. Semantic Tokens — 语义令牌
// ============================================================

export class Colors {
  // --- Brand ---
  static readonly primary = blue700;
  static readonly onPrimary = white;
  static readonly primaryDark = blue900;
  static readonly primaryLight = blue500;
  static readonly primaryBg = blue50;

  // --- Surface ---
  static readonly background = gray100;
  static readonly surface = white;
  static readonly surfaceVariant = gray50;
  static readonly foreground = gray900;

  // --- Text ---
  static readonly textPrimary = gray900;
  static readonly textSecondary = gray600;
  static readonly textMuted = gray500;
  static readonly textOnPrimary = white;

  // --- Border ---
  static readonly border = gray200;
  static readonly divider = gray200;
  static readonly borderLight = gray200;

  // --- Semantic Status ---
  static readonly success = green600;
  static readonly successBg = green50;
  static readonly warning = orange600;
  static readonly warningBg = orange50;
  static readonly error = red600;
  static readonly errorBg = red50;
  static readonly info = blue500;
  static readonly infoBg = blue50;

  // --- Interaction ---
  static readonly overlay = 'rgba(0, 0, 0, 0.45)';
  static readonly overlayLight = 'rgba(0, 0, 0, 0.06)';
  static readonly overlayWhite20 = 'rgba(255, 255, 255, 0.2)';
  static readonly overlayWhite85 = 'rgba(255, 255, 255, 0.85)';
  static readonly overlayWhite90 = 'rgba(255, 255, 255, 0.9)';

  // ============================================================
  // 3. Component Tokens — 组件级令牌
  // ============================================================

  // --- Work Order Status Colors ---
  static readonly statusPending: StatusColor = { fg: blue700, bg: blue50 };
  static readonly statusAssigned: StatusColor = { fg: blue500, bg: blue50 };
  static readonly statusRunning: StatusColor = { fg: green600, bg: green50 };
  static readonly statusPaused: StatusColor = { fg: orange600, bg: orange50 };
  static readonly statusProductionDone: StatusColor = { fg: purple600, bg: purple50 };
  static readonly statusReported: StatusColor = { fg: teal600, bg: teal50 };
  static readonly statusCompleted: StatusColor = { fg: green600, bg: green50 };
  static readonly statusScrapped: StatusColor = { fg: red600, bg: red50 };
  static readonly statusException: StatusColor = { fg: red500, bg: red50 };

  // Convenience maps for lookup
  static readonly statusFgMap: Record<string, string> = {
    '待派工': blue700, '已派工': blue500, '生产中': green500, '暂停中': orange500,
    '生产完成': purple600, '待报工': purple600, '已报工': teal500, '完工': green500,
    '报废': red500, '异常': red500
  };
  static readonly statusBgMap: Record<string, string> = {
    '待派工': blue50, '已派工': blue50, '生产中': green50, '暂停中': orange50,
    '生产完成': purple50, '待报工': purple50, '已报工': teal50, '完工': green50,
    '报废': red50, '异常': red50
  };

  // --- Role Colors ---
  static readonly roleAdmin: RoleColor = { avatar: '#EF5350', badge: red600, bg: red50 };
  static readonly roleLeader: RoleColor = { avatar: '#42A5F5', badge: blue700, bg: blue50 };
  static readonly roleOperator: RoleColor = { avatar: '#66BB6A', badge: green600, bg: green50 };
  static readonly roleInspector: RoleColor = { avatar: '#FFA726', badge: orange600, bg: orange50 };

  static readonly roleAvatarMap: Record<string, string> = {
    'admin': '#EF5350', 'leader': '#42A5F5', 'operator': '#66BB6A', 'inspector': '#FFA726'
  };
  static readonly roleBadgeMap: Record<string, RoleBadgeColor> = {
    'admin': { bg: red50, fg: red600 },
    'leader': { bg: blue50, fg: blue700 },
    'operator': { bg: green50, fg: green600 },
    'inspector': { bg: orange50, fg: orange600 }
  };

  // --- Device Status Colors ---
  static readonly deviceRunning = green500;
  static readonly deviceRunningBg = green50;
  static readonly deviceError = red500;
  static readonly deviceErrorBg = red50;
  static readonly deviceIdle = gray500;

  // --- Line Status Colors ---
  static readonly lineRunning = green600;
  static readonly linePaused = orange600;
  static readonly lineError = red600;
  static readonly lineIdle = gray500;

  // --- Inspection Conclusion Colors ---
  static readonly conclusionQualified = green600;
  static readonly conclusionUnqualified = red600;
  static readonly conclusionConcession = orange600;

  // --- Chart Colors ---
  static readonly chartPalette: string[] = [chartBlue, chartGreen, chartOrange, chartRed, chartPurple, chartTeal];
  static readonly chartGood = chartGreen;
  static readonly chartNg = chartRed;
  static readonly chartPass = chartBlue;

  // --- Dark mode state (reserved for future use) ---
  static readonly isDarkMode = false;
}
