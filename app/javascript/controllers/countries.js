import AppCtrl from "./app"

export default class CountriesCtrl extends AppCtrl {
  constructor() {
    super()

    this.searchForm = find('.country_search')
    this.searchInput = find('.search-input')
    this.currentValue = this.searchInput.value

    if (!this.isMobile) this.searchInput.focus()
  }

  search() {
    setTimeout(() => {
      const newValue = this.searchInput.value

      if (this.currentValue != newValue)
        this.currentValue = newValue
        submit(this.searchForm)
    }, 500)
  }
}
