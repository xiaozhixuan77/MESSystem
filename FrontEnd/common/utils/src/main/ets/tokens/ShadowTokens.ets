/**
 * MES 设计系统 — 阴影/立面令牌
 * 定义组件在不同层级上的视觉深度
 *
 * 引用方式：import { Shadows } from '@ohos/utils'
 */

interface ShadowPreset {
  radius: number;
  color: string;
  offsetY: number;
}

export class Shadows {
  // ============================================================
  // 卡片阴影
  // ============================================================

  /** 标准卡片 — 轻微浮起 */
  static readonly card: ShadowPreset = {
    radius: 16,
    color: 'rgba(0, 0, 0, 0.06)',
    offsetY: 2
  };

  /** 紧凑卡片 — 列表项 */
  static readonly cardCompact: ShadowPreset = {
    radius: 8,
    color: 'rgba(0, 0, 0, 0.04)',
    offsetY: 1
  };

  /** 悬浮卡片 — 弹窗/下拉菜单 */
  static readonly elevated: ShadowPreset = {
    radius: 20,
    color: 'rgba(0, 0, 0, 0.12)',
    offsetY: 4
  };

  /** 模态阴影 — 对话框遮罩 */
  static readonly modal: ShadowPreset = {
    radius: 24,
    color: 'rgba(0, 0, 0, 0.20)',
    offsetY: 8
  };

  /** 无阴影（扁平元素） */
  static readonly none: ShadowPreset = {
    radius: 0,
    color: 'rgba(0, 0, 0, 0)',
    offsetY: 0
  };

  // ============================================================
  // 常用组合预设
  // ============================================================

  /** 卡片容器: .shadow(Shadows.card) */
  static readonly cardPreset: ShadowPreset = {
    radius: 16,
    color: 'rgba(0, 0, 0, 0.06)',
    offsetY: 2
  };

  /** 底部操作栏: .shadow(Shadows.bottomBar) */
  static readonly bottomBar: ShadowPreset = {
    radius: 1,
    color: 'rgba(0, 0, 0, 0.08)',
    offsetY: -1
  };

  /** 按钮悬停发光 — 主操作按钮 */
  static readonly buttonGlow: ShadowPreset = {
    radius: 8,
    color: 'rgba(21, 101, 192, 0.25)',
    offsetY: 2
  };
}
