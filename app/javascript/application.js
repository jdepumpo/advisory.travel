// Dependencies
import { RalixApp } from 'ralix'
import "@hotwired/turbo-rails"
import "trix"
import "@rails/actiontext"

// Controllers
import AppCtrl      from './controllers/app'
import CountriesCtrl from './controllers/countries'

// Components
import RemoteModal  from './components/remote_modal'
import Tooltip      from './components/tooltip'
import Protomap     from './components/protomap'

const App = new RalixApp({
  routes: {
    '/countries$': CountriesCtrl,
    '/.*': AppCtrl
  },
  components: [
    RemoteModal,
    Tooltip,
    Protomap,
  ]
})

App.start()
