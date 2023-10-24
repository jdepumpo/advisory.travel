import AppCtrl from "./app"

export default class CountriesCtrl extends AppCtrl {
  constructor() {
    super()

    this.searchForm = find('.country_search')
    this.searchInput = find('.search-input')
    this.regionInput = find('.search-input')
    this.levelInput = find('.level-input')
    this.currentValue = this.searchInput.value
    this.currentRegion = this.regionInput.value
    this.currentLevel = this.levelInput.value

    if (!this.isMobile) this.searchInput.focus()
  }

  search() {
    setTimeout(() => {
      const newValue = this.searchInput.value
      const newRegion = this.regionInput.value
      const newLevel = this.levelInput.value

      if (this.currentValue != newValue || this.currentRegion != newRegion || this.currentLevel != newLevel)
        this.currentValue = newValue
        this.currentRegion = newRegion
        this.currentLevel = newLevel
        submit(this.searchForm)
    }, 500)
  }
}
