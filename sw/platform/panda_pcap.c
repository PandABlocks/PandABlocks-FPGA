/*
 * Linux platform driver example
 *
 * Copyright (c) 2008, Atmel Corporation All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. The name of ATMEL may not be used to endorse or promote products
 *    derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ATMEL ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE EXPRESSLY AND SPECIFICALLY DISCLAIMED. IN NO EVENT SHALL ATMEL
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
#include <linux/clk.h>
#include <linux/gpio.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/irq.h>
#include <linux/irqchip/chained_irq.h>
#include <linux/irqdomain.h>
#include <linux/module.h>
#include <linux/platform_device.h>

#define DRIVER_NAME "panda-pcap"

/**
 * struct panda_pcap - pcap device private data structure
 * @base_addr:  base address of the GPIO device
 * @irq:        irq associated with the controller
 * @irq_base:   base of IRQ number for interrupt
 */

struct zynq_pcap {
    void __iomem *base_addr;
    unsigned int irq;
    unsigned int irq_base;
};

static inline u32 pcap_readreg(void __iomem *offset)
{
        return readl_relaxed(offset);
}

static inline void pcap_writereg(void __iomem *offset, u32 val)
{
        writel_relaxed(val, offset);
}

static irqreturn_t panda_pcap_isr(int irq, void *dev_id)
{
    printk(KERN_INFO "IRQ received\n");
    return IRQ_HANDLED;
}

static int panda_pcap_probe(struct platform_device *pdev)
{
    int ret;
    struct zynq_pcap *pcap;
    struct resource *res;
    u32 data;

    pcap = devm_kzalloc(&pdev->dev, sizeof(*pcap), GFP_KERNEL);
    if (!pcap)
        return -ENOMEM;

    platform_set_drvdata(pdev, pcap);

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    pcap->base_addr = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(pcap->base_addr))
            return PTR_ERR(pcap->base_addr);

    pcap->irq = platform_get_irq(pdev, 0);
    if (pcap->irq <= 0) {
        dev_err(&pdev->dev, "irq resource not found\n");
        return -ENXIO;
    }

    ret = devm_request_irq(&pdev->dev, pcap->irq, panda_pcap_isr,
                           0, pdev->name, pcap);
    if (ret != 0) {
        dev_err(&pdev->dev, "request_irq failed\n");
        return -ENXIO;
    }


    printk(KERN_INFO "platform_device name is %s\n", pdev->name);

    data = 0x1234;
    pcap_writereg(pcap->base_addr, data);
    printk(KERN_INFO "Read base+0 = %08x\n", pcap_readreg(pcap->base_addr));

    printk(KERN_INFO "platform_device irq_num is %08x\n", pcap->irq);

    return 0;
}

static int panda_pcap_remove(struct platform_device *pdev)
{
    /* Add per-device cleanup code here */
    dev_notice(&pdev->dev, "remove() called\n");

    return 0;
}

static struct of_device_id panda_pcap_of_match[] = {
//    { .compatible = "dls-cs1,panda-pcap-1.0", },
    { .compatible = "xlnx,panda-pcap-1.0", },
    { /* end of table */ }
};
MODULE_DEVICE_TABLE(of, panda_pcap_of_match);

static struct platform_driver panda_pcap_driver = {
        .probe          = panda_pcap_probe,
        .remove         = panda_pcap_remove,
        .driver = {
                .name   = DRIVER_NAME,
                .owner  = THIS_MODULE,
                .of_match_table = panda_pcap_of_match,
        },
};

static int __init panda_pcap_init(void)
{
        return platform_driver_register(&panda_pcap_driver);

}
module_init(panda_pcap_init);

static void __exit panda_pcap_exit(void)
{
        platform_driver_unregister(&panda_pcap_driver);
}
module_exit(panda_pcap_exit);

/* Information about this module */
MODULE_DESCRIPTION("Platform driver example");
MODULE_AUTHOR("Isa Uzun");
MODULE_LICENSE("GPL");
