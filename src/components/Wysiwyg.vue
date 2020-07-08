<template>
  <div>
    <div class="mb-2">
      <button :class="{ 'active': currentStyle === 'b' }" @click="toggleStyle('b')">Bold</button>
      <button :class="{ 'active': currentStyle === 'i' }" @click="toggleStyle('i')">Italic</button>
    </div>
    <div ref="container">
      <component v-for="(item, index) in styles" :is="item.type" :key="index">{{ item.value }}</component>
      <input ref="input" :value="''" :style="inputStyle" @input="handleInput"/>
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
      styles: [{ type: 'span', value: '' }]
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
    }
  },
  methods: {
    handleInput: function (e) {
      const style = this.styles.pop()
      style.value += e.target.value
      this.styles.push(style)
    },
    toggleStyle: function (style) {
      const selection = window.getSelection()
      if (selection && !selection.isCollapsed && this.$refs.container.contains(selection.anchorNode) && this.$refs.container.contains(selection.focusNode)) {
        const nodes = this.$refs.container.childNodes
        const anchorNode = selection.anchorNode.nodeType === Node.TEXT_NODE ? selection.anchorNode.parentNode : selection.anchorNode
        const focusNode = selection.focusNode.nodeType === Node.TEXT_NODE ? selection.focusNode.parentNode : selection.focusNode
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
        const precedingStyles = this.styles.filter((_, i) => i < startIndex)
        const nextStyles = this.styles.filter((_, i) => i > endIndex)
        const startStyle = this.styles[startIndex]
        if (selection.anchorOffset > 0) {
          precedingStyles.push({ type: startStyle.type, value: startStyle.value.substring(0, selection.anchorOffset) })
        }
        let newValue = startStyle.value.substring(selection.anchorOffset)
        newValue += this.styles.filter((_, i) => i > startIndex && i < endIndex).map(({ value }) => value).join()
        const endStyle = this.styles[endIndex]
        if (selection.focusOffset > 0) {
          console.log(selection.focusOffset, endStyle.value.length)
          nextStyles.unshift({ type: endStyle.type, value: endStyle.value.substring(selection.focusOffset) })
        }
        newValue += endStyle.value.substring(0, selection.focusOffset)
        this.styles = [...precedingStyles, { type: style, value: newValue }, ...nextStyles]
        selection.empty()
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
input {
  border: none;

  &:focus {
    outline: none;
  }
}
</style>
