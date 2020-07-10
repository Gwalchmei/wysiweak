<template>
  <div>
    <div class="mb-2">
      <button :class="{ 'active': currentStyle === 'span'}" @click="toggleStyle('span')">Normal</button>
      <button :class="{ 'active': currentStyle === 'b' }" @click="toggleStyle('b')">Bold</button>
      <button :class="{ 'active': currentStyle === 'i' }" @click="toggleStyle('i')">Italic</button>
    </div>
    <div ref="container" tabindex="0" @keydown.backspace="deleteText" class="wysiwyg-container" style="{ wordBreak: 'break-word' }" @click.self="focusInput" @keydown.enter="breakLine">
      <component v-for="item in precedingStyles" :is="item.type" :key="item.id" @click="moveCursor(item, $event)">{{ item.value || null }}</component>
      <input ref="input" :value="''" :style="inputStyle" @input="handleInput" class="wysiwyg-input" />
      <component v-for="item in nextStyles" :is="item.type" :key="item.id" @click="moveCursor(item, $event)">{{ item.value || null }}</component>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Wysiwyg',
  data: function () {
    return {
      currentValue: '',
      currentStyle: 'span',
      styles: [{ type: 'span', value: '' }],
      inputIndex: null
    }
  },
  computed: {
    inputStyle: function () {
      if (this.currentStyle === 'b') {
        return { fontWeight: 'bold' }
      }
      if (this.currentStyle === 'i') {
        return { fontStyle: 'italic' }
      }
      return {}
    },
    precedingStyles: function () {
      return this.styles.map((style, i) => ({ ...style, id: i }))
        .filter((_, i) => this.inputIndex === null || i < this.inputIndex)
    },
    nextStyles: function () {
      return this.styles.map((style, i) => ({ ...style, id: i }))
        .filter((_, i) => this.inputIndex !== null && i >= this.inputIndex)
    }
  },
  mounted: function () {
    this.$refs.input.focus()
  },
  methods: {
    focusInput: function () {
      this.$refs.input.focus()
    },
    moveCursor: function (item, e) {
      const selection = window.getSelection()
      if (selection.isCollapsed && !(selection.anchorNode.nodeType === Node.ELEMENT_NODE && selection.anchorNode.tagName === 'INPUT')) {
        const nodes = Array.from(this.$refs.container.childNodes).filter((node) => node.tagName !== 'INPUT')
        const anchorNode = selection.anchorNode.nodeType === Node.TEXT_NODE ? selection.anchorNode.parentNode : selection.anchorNode
        const index = nodes.findIndex((node) => node === anchorNode)
        if (index > -1) {
          const style = this.styles[index]
          const precedingStyles = this.styles.filter((_, i) => i < index)
          const nextStyles = this.styles.filter((_, i) => i > index)
          if (selection.anchorOffset > 0) {
            precedingStyles.push(({ type: style.type, value: style.value.substring(0, selection.anchorOffset) }))
            if (selection.anchorOffset < style.value.length) {
              nextStyles.unshift({ type: style.type, value: style.value.substring(selection.anchorOffset) })
            }
          } else {
            nextStyles.unshift(style)
          }
          this.styles = [...precedingStyles, ...nextStyles]
          this.inputIndex = nextStyles.length > 0 ? precedingStyles.length : null
          setTimeout(() => this.$refs.input.focus(), 1)
        }
      }
    },
    hasSelectedText: function () {
      const selection = window.getSelection()
      return selection &&
        !selection.isCollapsed &&
        this.$refs.container.contains(selection.anchorNode) &&
        this.$refs.container.contains(selection.focusNode)
    },
    getSelectionRange: function () {
      if (this.hasSelectedText()) {
        const selection = window.getSelection()
        const nodes = Array.from(this.$refs.container.childNodes).filter((node) => node.tagName !== 'INPUT')
        const anchorNode = selection.anchorNode.nodeType === Node.TEXT_NODE ? selection.anchorNode.parentNode : selection.anchorNode
        const focusNode = selection.focusNode.nodeType === Node.TEXT_NODE ? selection.focusNode.parentNode : selection.focusNode
        let anchorOffset = selection.anchorOffset
        let focusOffset = selection.focusOffset
        let startIndex = 0
        let endIndex = 0
        for (let i = 0; i < nodes.length; i += 1) {
          if (nodes[i] === anchorNode) {
            startIndex = i
          }
          if (nodes[i] === focusNode) {
            endIndex = i
          }
        }
        if (startIndex > endIndex) {
          const tempIndex = startIndex
          const tempOffset = anchorOffset
          startIndex = endIndex
          anchorOffset = focusOffset
          endIndex = tempIndex
          focusOffset = tempOffset
        }
        if (startIndex === endIndex && anchorOffset > focusOffset) {
          const tempOffset = anchorOffset
          anchorOffset = focusOffset
          focusOffset = tempOffset
        }

        selection.empty()

        return {
          from: startIndex,
          fromOffset: anchorOffset,
          to: endIndex,
          toOffset: focusOffset
        }
      }

      return null
    },
    setStyles: function (styles) {
      this.styles = styles.reduce((clean, style) => {
        if (clean.length > 0) {
          const last = clean.pop()
          if (last.type === style.type && style.value) {
            return [...clean, { type: last.type, value: last.value + style.value }]
          }

          return [...clean, last, style]
        }

        return [clean, style]
      }, [])
      this.inputIndex = null
    },
    deleteText: function () {
      const selectionRange = this.getSelectionRange()
      if (selectionRange) {
        const precedingStyles = this.styles.filter((_, i) => i < selectionRange.from)
        const nextStyles = this.styles.filter((_, i) => i > selectionRange.to)
        const startStyle = this.styles[selectionRange.from]
        if (selectionRange.fromOffset > 0) {
          precedingStyles.push({ type: startStyle.type, value: startStyle.value.substring(0, selectionRange.fromOffset) })
        }
        if (selectionRange.from === selectionRange.to) {
          if (selectionRange.toOffset > 0) {
            nextStyles.unshift({ type: startStyle.type, value: startStyle.value.substring(selectionRange.toOffset) })
          }
          this.setStyles([
            ...precedingStyles,
            ...nextStyles
          ])
        } else {
          const endStyle = this.styles[selectionRange.to]
          if (selectionRange.toOffset > 0) {
            nextStyles.unshift({ type: endStyle.type, value: endStyle.value.substring(selectionRange.toOffset) })
          }
          this.setStyles([...precedingStyles, ...nextStyles])
        }
      } else {
        if (this.styles.length > 0) {
          const style = this.precedingStyles.pop()
          if (style && style.value) {
            style.value = style.value.slice(0, -1)
            if (style.value.length > 0) {
              this.styles = [...this.precedingStyles, style, ...this.nextStyles]
            } else {
              this.styles = [...this.precedingStyles, ...this.nextStyles]
              this.inputIndex = this.inputIndex > 0 ? this.inputIndex - 1 : this.inputIndex
              setTimeout(() => this.$refs.input.focus(), 1)
            }
          }
        }
      }
    },
    handleInput: function (e) {
      if (this.styles.length > 0) {
        const style = this.precedingStyles.length > 0
          ? this.precedingStyles.pop()
          : this.nextStyles.shift()
        if (style.type === this.currentStyle) {
          style.value += e.target.value
          this.styles = [...this.precedingStyles, style, ...this.nextStyles]
        } else {
          this.styles = [...this.precedingStyles, style, { type: this.currentStyle, value: e.target.value }, ...this.nextStyles]
          this.inputIndex += 1
          setTimeout(() => this.$refs.input.focus(), 1)
        }
      } else {
        this.styles.push({ type: this.currentStyle, value: e.target.value })
      }
    },
    breakLine: function () {
      this.styles = [...this.precedingStyles, { type: 'br' }, ...this.nextStyles]
      this.inputIndex += 1
      setTimeout(() => this.$refs.input.focus(), 1)
    },
    toggleStyle: function (style) {
      const selectionRange = this.getSelectionRange()
      if (selectionRange) {
        const precedingStyles = this.styles.filter((_, i) => i < selectionRange.from)
        const nextStyles = this.styles.filter((_, i) => i > selectionRange.to)
        const startStyle = this.styles[selectionRange.from]
        if (selectionRange.fromOffset > 0) {
          precedingStyles.push({ type: startStyle.type, value: startStyle.value.substring(0, selectionRange.fromOffset) })
        }
        if (selectionRange.from === selectionRange.to) {
          if (selectionRange.toOffset > 0) {
            nextStyles.unshift({ type: startStyle.type, value: startStyle.value.substring(selectionRange.toOffset) })
          }
          this.setStyles([
            ...precedingStyles,
            { type: style, value: startStyle.value.substring(selectionRange.fromOffset, selectionRange.toOffset) },
            ...nextStyles
          ])
        } else {
          let newValue = startStyle.value.substring(selectionRange.fromOffset)
          newValue += this.styles
            .filter((_, i) => i > selectionRange.from && i < selectionRange.to)
            .map(({ value }) => value || '')
            .join('')
          const endStyle = this.styles[selectionRange.to]
          if (selectionRange.toOffset > 0) {
            nextStyles.unshift({ type: endStyle.type, value: endStyle.value.substring(selectionRange.toOffset) })
          }
          newValue += endStyle.value.substring(0, selectionRange.toOffset)
          this.setStyles([...precedingStyles, { type: style, value: newValue }, ...nextStyles])
        }
      } else {
        this.currentStyle = this.currentStyle === style ? 'span' : style
        this.styles.push({ type: this.currentStyle, value: '' })
        this.$refs.input.focus()
      }
    }
  }
}
</script>

<style lang="scss">
.wysiwyg-input {
  border: none;
  width: 1px;

  &:focus {
    outline: none;
  }
}

.wysiwyg-container {
  word-break: break-word;
  border: 1px solid #a9a9a9;
  text-align: left;

  &:focus {
    outline: none;
  }
}
</style>
