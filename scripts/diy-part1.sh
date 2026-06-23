#!/bin/bash
# =============================================================
# diy-part1.sh — 在 feeds update/install 之前执行
# 用途：添加第三方 feed、克隆额外包
# =============================================================
set -euo pipefail

echo "▶ [diy-part1] 开始..."

# ─────────────────────────────────────────────────────────────
# 1. 添加第三方 feed
#    ImmortalWrt 自身 feeds.conf.default 已含 packages/luci/routing
#    只需补充 LEDE/OpenWrt 没有的三方包
# ─────────────────────────────────────────────────────────────

# OpenClash — 独立 feed（dev 分支最新）
# ImmortalWrt packages feed 里也有 openclash，但可能版本较旧
# 若官方 feed 版本足够新可以注释掉这行
grep -q "openclash" feeds.conf.default || \
  echo "src-git openclash https://github.com/vernesong/OpenClash.git;dev" \
  >> feeds.conf.default

# QModem — 4G/5G 模组管理（含 luci-app-qmodem / qmodem-sms / qmodem-ttl）
grep -q "qmodem" feeds.conf.default || \
  echo "src-git qmodem https://github.com/FUjr/modem_feeds.git;main" \
  >> feeds.conf.default

# Lucky — DDNS + 内网穿透一体
grep -q "lucky" feeds.conf.default || \
  echo "src-git lucky https://github.com/gdy666/luci-app-lucky.git" \
  >> feeds.conf.default

# ── 你的自定义插件仓库（按需取消注释）────────────────────────
# grep -q "dongzai" feeds.conf.default || \
#   echo "src-git dongzai https://github.com/YOUR_NAME/YOUR_PKGS.git;main" \
#   >> feeds.conf.default

echo "▶ feeds.conf.default 已更新："
grep -v "^#" feeds.conf.default

# ─────────────────────────────────────────────────────────────
# 2. 直接克隆到 package/ 的包（不走 feed 的方式）
#    适合单个插件仓库，比 feed 更精准控制版本
# ─────────────────────────────────────────────────────────────

# luci-app-iptv-manager（你自己维护的 IPTV 管理插件）
# if [ ! -d "package/luci-app-iptv-manager" ]; then
#   git clone --depth=1 \
#     https://github.com/YOUR_NAME/luci-app-iptv-manager.git \
#     package/luci-app-iptv-manager
# fi

# luci-app-unicast-proxy
# if [ ! -d "package/luci-app-unicast-proxy" ]; then
#   git clone --depth=1 \
#     https://github.com/YOUR_NAME/luci-app-unicast-proxy.git \
#     package/luci-app-unicast-proxy
# fi

# ─────────────────────────────────────────────────────────────
# 3. 修改默认 feeds 源（可选：替换为国内镜像加速下载）
# ─────────────────────────────────────────────────────────────
# sed -i 's|https://github.com/immortalwrt/packages|https://mirror.ghproxy.com/https://github.com/immortalwrt/packages|g' feeds.conf.default
# sed -i 's|https://github.com/immortalwrt/luci|https://mirror.ghproxy.com/https://github.com/immortalwrt/luci|g' feeds.conf.default

echo "▶ [diy-part1] 完成 ✓"

