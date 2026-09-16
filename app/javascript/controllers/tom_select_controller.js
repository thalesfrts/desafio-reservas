import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.select = new TomSelect(this.element, {
      plugins: ['remove_button'],
      placeholder: 'Busque o colaborador digitando aqui...',
      searchField: ['text']
    })
  }

  disconnect() {
    if (this.select) {
      this.select.destroy()
    }
  }
}