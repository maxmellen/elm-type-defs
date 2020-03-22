(() => {
  type Attribute = "editor-value" | "read-only";

  class CodeViewer extends HTMLElement {
    private editor: CodeMirror.Editor | null = null;
    private editorValue: string = "";
    private readOnly: boolean = false;

    static get observedAttributes() {
      return ["editor-value", "read-only"];
    }

    connectedCallback() {
      this.editor = CodeMirror(this, {
        mode: "javascript",
        value: this.editorValue,
        readOnly: this.readOnly
      });

      this.editor.on("changes", () => {
        let event = new CustomEvent("editorChanged", {
          detail: { value: this.editor!.getValue() }
        });

        this.dispatchEvent(event);
      });
    }

    attributeChangedCallback(
      name: Attribute,
      _oldValue: string | null,
      newValue: string | null
    ) {
      switch (name) {
        case "editor-value":
          if (!newValue) return;
          if (newValue === this.editorValue) return;
          this.editorValue = newValue;
          if (!this.editor) return;
          if (newValue === this.editor.getValue()) return;
          this.editor.setValue(newValue);
          break;
        case "read-only":
          let readOnly = !(newValue === null);
          if (readOnly === this.readOnly) return;
          this.readOnly = readOnly;
          if (!this.editor) return;
          this.editor.setOption("readOnly", readOnly);
          break;
        default:
          console.warn("Unexpected attribute name:", name);
      }
    }
  }

  customElements.define("code-viewer", CodeViewer);
})();
