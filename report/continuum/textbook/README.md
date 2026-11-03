# 完整推导说明书 / 詳細導出説明書

2026-11-03。两份 PDF 各 31 页、92 组矢量公式、31 个章节书签。

- [中文 PDF](../../../output/pdf/continuum_ancf_textbook_zh.pdf)
- [日本語 PDF](../../../output/pdf/continuum_ancf_textbook_ja.pdf)

本次为文档工作，数值结果沿用 2026-11-02 符号修正后的验证。旧说明书保留。
`content.json` 包含对齐的中日文段落和共享 TeX 公式；HTML 是完整离线排版源。
`source_sha256.json` 记录模型源码和数值 CSV 的校验值。

## 重建

依赖：Python 3 与 pypdf、Node.js、mathjax-full 3.2.2、playwright、Google Chrome、Arial Unicode 字体。

```text
python scripts/build_continuum_textbook.py
node scripts/render_continuum_textbook.cjs
python scripts/finalize_continuum_textbook.py
```

Node 脚本支持 MATHJAX_ROOT、PLAYWRIGHT_ROOT、CHROME_PATH 环境变量。当前默认依赖位置对应本机；换机器时应调整路径及字体路径。渲染脚本自动检查纵向溢出；最终脚本检查页数、章节书签与公式编号。

质量检查：中日文所有页已渲染检查，关键矩阵页作放大检查；Hermite 单元质量和重力显式矩阵以有理数积分独立核对。公式矢量化保留放大清晰度，但不保证可从 PDF 文本提取还原 LaTeX；编辑时应使用 content.json 或构建脚本。
