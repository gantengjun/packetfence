<template>
  <b-form @submit.prevent="save()">
    <b-card no-body>
      <b-card-header>
        <b-button-close @click="close" v-b-tooltip.hover.left.d300 :title="$t('Close [ESC]')"><icon name="times"></icon></b-button-close>
        <h4 class="mb-0">{{ $t('DNS Log Entry')}} <strong v-text="id"></strong></h4>
      </b-card-header>
      <pf-form-row :column-label="$t('IP Address')">{{ item.ip }}</pf-form-row>
      <pf-form-row :column-label="$t('MAC Address')">{{ item.mac }}</pf-form-row>
      <pf-form-row :column-label="$t('Qname')">{{ item.qname }}</pf-form-row>
      <pf-form-row :column-label="$t('Qtype')">{{ item.qtype }}</pf-form-row>
      <pf-form-row :column-label="$t('Answer')">{{ item.answer }}</pf-form-row>
      <pf-form-row :column-label="$t('Scope')">{{ item.scope }}</pf-form-row>
      <pf-form-row :column-label="$t('Created At')">{{ item.created_at }}</pf-form-row>
    </b-card>
  </b-form>
</template>

<script>
import pfFormRow from '@/components/pfFormRow'

export default {
  name: 'DnsLogView',
  components: {
    pfFormRow
  },
  props: {
    storeName: { // from router
      type: String,
      default: null,
      required: true
    },
    id: String // from router
  },
  data () {
    return {
      item: {},
      tabIndex: 0,
      tabTitle: ''
    }
  },
  computed: {
    isLoading () {
      return this.$store.getters[`${this.storeName}/isLoading`]
    },
    escapeKey () {
      return this.$store.getters['events/escapeKey']
    }
  },
  methods: {
    init () {
      this.$store.dispatch(`${this.storeName}/getItem`, this.id).then(item => {
        this.item = item
      })
    },
    ifTab (set) {
      return this.$refs.tabs && set.includes(this.$refs.tabs.tabs[this.tabIndex].title)
    },
    close () {
      this.$router.push({ name: 'dnslogs' })
    }
  },
  created () {
    this.init()
  },
  watch: {
    escapeKey (pressed) {
      if (pressed) this.close()
    }
  }
}
</script>
