#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

__visible struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0xdae5e913, __VMLINUX_SYMBOL_STR(module_layout) },
	{ 0x58599507, __VMLINUX_SYMBOL_STR(platform_driver_unregister) },
	{ 0x9fd8b2d7, __VMLINUX_SYMBOL_STR(__platform_driver_register) },
	{ 0xefd6cf06, __VMLINUX_SYMBOL_STR(__aeabi_unwind_cpp_pr0) },
	{ 0x4e3a4464, __VMLINUX_SYMBOL_STR(dev_err) },
	{ 0x2dce49f5, __VMLINUX_SYMBOL_STR(devm_request_threaded_irq) },
	{ 0x24390b8e, __VMLINUX_SYMBOL_STR(platform_get_irq) },
	{ 0x327124cf, __VMLINUX_SYMBOL_STR(devm_ioremap_resource) },
	{ 0xd3b6c45d, __VMLINUX_SYMBOL_STR(platform_get_resource) },
	{ 0x4985f0ef, __VMLINUX_SYMBOL_STR(devm_kmalloc) },
	{ 0x27e1a049, __VMLINUX_SYMBOL_STR(printk) },
	{ 0x2e5810c6, __VMLINUX_SYMBOL_STR(__aeabi_unwind_cpp_pr1) },
	{ 0x3b68f458, __VMLINUX_SYMBOL_STR(dev_notice) },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("of:N*T*Cdls-cs1,panda-pcap-1.0*");
