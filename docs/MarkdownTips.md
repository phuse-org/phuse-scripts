# Biggest header
## Big header
### Middle header
#### And they keep getting smaller
##### GitHub Markdown tips:

Making a TOC -- automatic anchors for header text (anchor text is all lower-case, and hyphens replace blanks)
* [Styling text](#styling-text)
* [Links](#links)
* [Lists](#lists)
* [Code blocks with language-specific syntax highlighting](#code-blocks-with-language-specific-syntax-highlighting)

###### Styling text
* **bold**
* *italics*
* `monospace`
* ~~strikethrough~~
* in-line `code` has back-ticks around it like <code>`code`</code>

###### Links
* More Markdown details in [GitHub's Markdown Basics](http://help.github.com/articles/markdown-basics/)
* Adam Pritchard's [GitHub Markdown Cheatsheet](http://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)

###### Lists

1. Ordered are aligned with numbers.
  1. ordered sub-lists simply have leading spaces
  2. like this
* Unordered lists are aligned with `*`, `+` or `-` characters
  + and again sub-lists have leading spaces
  - and it seems that you can mix `*`, `+` and `-` characters

###### Code blocks with language-specific syntax highlighting

* SAS highlighting using a back-tick blocks like <code>```SAS ...lines of code... ```</code>

```SAS
put "Hello, World!";
* code block with SAS syntax highlighting;
```

* R highlighting using a back-tick blocks like <code>```R ...lines of code... ```</code>

```R
cat("Hello", "World", sep = ", ")
# code block with R syntax highlighting
```
