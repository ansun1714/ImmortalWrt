#!/bin/bash
# =============================================================
# diy-part2.sh — cp .config 之后、make defconfig 之前执行
# 用途：修改默认配置、适配 LEDE→ImmortalWrt 差异
# =============================================================
set -euo pipefail

echo "▶ [diy-part2] 开始..."

# ─────────────────────────────────────────────────────────────
# 1. 修改默认 IP / 主机名
#    ImmortalWrt 24.10 用 /etc/board.d/99-default_network 控制
#    更稳妥的方式是直接改 config_generate
# ─────────────────────────────────────────────────────────────
sed -i 's/192\.168\.1\.1/192.168.10.1/g' \
  package/base-files/files/bin/config_generate 2>/dev/null || \
  echo "  ! config_generate 路径不存在，跳过（通过 uci-defaults 设置）"

# ImmortalWrt 默认主机名是 ImmortalWrt，改为设备名
sed -i 's/ImmortalWrt/WH3000-Pro/g' \
  package/base-files/files/bin/config_generate 2>/dev/null || true

# 版本标识（显示在 LuCI 页脚）
BUILD_DATE=$(date +%Y%m%d)
if [ -f "package/base-files/files/etc/openwrt_release" ]; then
  sed -i "s/DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='DONGZAI-ImmortalWrt ${BUILD_DATE}'/" \
    package/base-files/files/etc/openwrt_release
fi

echo "  ✓ 默认 IP → 192.168.10.1，主机名 → WH3000-Pro"

# ─────────────────────────────────────────────────────────────
# 2. ImmortalWrt vs LEDE 包名差异处理
#    LEDE 有的包 ImmortalWrt 里名字可能不同或已内置
# ─────────────────────────────────────────────────────────────

# 2a. samba：ImmortalWrt 24.10 主推 samba4，samba36 可能不存在
#     将 samba36-server 替换为 samba4-server
if grep -q "CONFIG_PACKAGE_samba36-server=y" .config; then
  sed -i 's/CONFIG_PACKAGE_samba36-server=y/CONFIG_PACKAGE_samba4-server=y/' .config
  sed -i 's/CONFIG_PACKAGE_luci-app-samba=y/CONFIG_PACKAGE_luci-app-samba4=y/' .config
  sed -i 's/CONFIG_PACKAGE_luci-i18n-samba-zh-cn=y/CONFIG_PACKAGE_luci-i18n-samba4-zh-cn=y/' .config
  echo "  ✓ samba36 → samba4（ImmortalWrt 24.10 适配）"
fi

# 2b. wpad：ImmortalWrt 官方已内置较完整的 wpad
#     wpad-openssl-mbedtls 在 ImmortalWrt 中存在，保持不变
#     如果编译报冲突，改为 wpad-basic-mbedtls
# （这里不做修改，等出现报错时手动处理）

# 2c. ImmortalWrt 24.10 的 TurboACC 包名确认
#     某些版本叫 luci-app-turboacc，某些叫 kmod-shortcut-fe
#     保留 luci-app-turboacc，若不存在 defconfig 会自动忽略

# 2d. SSR-Plus 在 ImmortalWrt packages feed 里已包含，无需额外克隆
# 2e. OpenClash 通过 diy-part1.sh 的独立 feed 引入

# ─────────────────────────────────────────────────────────────
# 3. CONFIG_TESTING_KERNEL 处理
#    LEDE 里 =y 启用 6.6；ImmortalWrt 24.10 默认就是 6.6，无此选项
# ─────────────────────────────────────────────────────────────
sed -i '/^CONFIG_TESTING_KERNEL/d' .config
sed -i '/^#CONFIG_LINUX_6_6/d'     .config
echo "  ✓ 移除 LEDE 专属的 CONFIG_TESTING_KERNEL"

# ─────────────────────────────────────────────────────────────
# 4. 禁用调试内核选项（防 GitHub Actions OOM）
# ─────────────────────────────────────────────────────────────
for opt in \
  CONFIG_KERNEL_DEBUG_KERNEL \
  CONFIG_KERNEL_DEBUG_INFO \
  CONFIG_KERNEL_DEBUG_FS \
  CONFIG_KERNEL_DYNAMIC_DEBUG \
  CONFIG_KERNEL_KASAN \
  CONFIG_KERNEL_KCSAN \
  CONFIG_KERNEL_UBSAN \
  CONFIG_KERNEL_DEBUG_SPINLOCK \
  CONFIG_KERNEL_DEBUG_MUTEXES \
  CONFIG_KERNEL_LOCKDEP \
  CONFIG_KERNEL_PROVE_LOCKING; do
  sed -i "s/^${opt}=y/# ${opt} is not set/" .config 2>/dev/null || true
done
echo "  ✓ 调试内核选项已禁用"

# ─────────────────────────────────────────────────────────────
# 5. 补充 ImmortalWrt 优化选项
# ─────────────────────────────────────────────────────────────
# LuCI 编译时压缩（加速页面加载）
grep -q "CONFIG_LUCI_SRCDIET" .config || echo "CONFIG_LUCI_SRCDIET=y" >> .config
grep -q "CONFIG_LUCI_JSMIN"   .config || echo "CONFIG_LUCI_JSMIN=y"   >> .config
grep -q "CONFIG_LUCI_CSSTIDY" .config || echo "CONFIG_LUCI_CSSTIDY=y" >> .config

# ccache
grep -q "CONFIG_CCACHE" .config || echo "CONFIG_CCACHE=y" >> .config

# 分区大小确认（448MB）
if ! grep -q "CONFIG_TARGET_ROOTFS_PARTSIZE=448" .config; then
  sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=448/' .config
fi

echo "  ✓ 优化选项已注入"

# ─────────────────────────────────────────────────────────────
# 6. ImmortalWrt 24.10 特有：默认区域设置
#    ImmortalWrt 已把 zh_Hans/CN 预置，这里做兜底
# ─────────────────────────────────────────────────────────────
grep -q "CONFIG_LUCI_LANG_zh_Hans" .config || \
  echo "CONFIG_LUCI_LANG_zh_Hans=y" >> .config

echo "▶ [diy-part2] 完成 ✓"
echo "  最终分区大小：$(grep CONFIG_TARGET_ROOTFS_PARTSIZE .config)"

