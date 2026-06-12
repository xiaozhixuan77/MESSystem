/**
 * MES 设计系统 — 间距令牌
 * 基于 4dp 基准网格系统，兼容 HarmonyOS 响应式布局
 *
 * 引用方式：import { Spacing } from '@ohos/utils'
 */

export class Spacing {
  // ============================================================
  // 基础间距 (4dp grid)
  // ============================================================
  static readonly space2 = 2;
  static readonly space4 = 4;
  static readonly space6 = 6;
  static readonly space8 = 8;
  static readonly space10 = 10;
  static readonly space12 = 12;
  static readonly space14 = 14;
  static readonly space16 = 16;
  static readonly space20 = 20;
  static readonly space24 = 24;
  static readonly space28 = 28;
  static readonly space32 = 32;
  static readonly space36 = 36;
  static readonly space48 = 48;

  // ============================================================
  // 语义间距
  // ============================================================

  // Page-level
  static readonly pageHorizontal = 16;
  static readonly pageTop = 16;
  static readonly pageBottom = 28;

  // Card
  static readonly cardPaddingH = 16;
  static readonly cardPaddingV = 16;
  static readonly cardGap = 12;
  static readonly cardRadius = 12;

  // List
  static readonly listItemGap = 8;
  static readonly listSectionGap = 12;

  // Form
  static readonly formFieldGap = 16;
  static readonly formLabelGap = 4;
  static readonly formSectionGap = 24;

  // Section
  static readonly sectionTitleBottom = 10;
  static readonly sectionTitleMargin = 14;

  // Status tag
  static readonly tagPaddingH = 8;
  static readonly tagPaddingV = 2;

  // Icon
  static readonly iconSize = 20;
  static readonly iconSizeLarge = 24;
  static readonly iconSizeSmall = 16;

  // Button
  static readonly buttonPaddingH = 16;
  static readonly buttonPaddingV = 12;
  static readonly buttonGap = 12;

  // Sidebar
  static readonly sidebarSm = 0;
  static readonly sidebarMd = 120;
  static readonly sidebarLg = 160;

  // Border radius
  static readonly radiusSm = 4;
  static readonly radiusMd = 8;
  static readonly radiusLg = 12;
  static readonly radiusXl = 16;
  static readonly radiusFull = 20;
  static readonly radiusRound = 9999;
}
