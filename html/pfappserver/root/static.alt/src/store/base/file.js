/**
* Base file store module. Used by:
*   pfFormUpload
*/
const types = {
  LOADING: 'loading',
  SUCCESS: 'success',
  ERROR: 'error'
}

export default class FileStore {
  constructor (blob, encoding) {
    this.blob = blob
    this.encoding = encoding
  }

  module () {
    const state = () => {
      return {
        /**
         * private state(s)
        **/
        blob: this.blob || null, // File
        status: null,
        offsets: [0], // private map of line # => byte offset
        chunkSize: 1024 * 1024, // FileReader.slice chunk size (bytes)

        /**
         * public state(s)
        **/
        file: {
          offsets: [], // temporary

          name: this.blob.name || null, // from File|Blob
          lastModified: this.blob.lastModified || null, // from File|Blob
          size: this.blob.size || null, // from File|Blob
          type: this.blob.type || null, // from File|Blob
          encoding: this.encoding || 'utf-8', // user defined character encoding
          percent: 0, // FileReader onprogress percent
          result: null, // FileReader onload result
          error: null // FileReader onerror error
        }
      }
    }

    const getters = {
      file: state => state.file,
      isError: state => state.status === types.ERROR,
      isLoading: state => state.status === types.LOADING
    }

    const actions = {
      setEncoding: ({ commit }, encoding) => {
        commit('SET_ENCODING', encoding)
      },
      setChunkSize: ({ commit }, size) => {
        commit('SET_CHUNK_SIZE', size)
      },
      readAsText: ({ commit, state }) => {
        commit('SET_READ_AS_TEXT')
      },
      readAsStream: ({ commit, state, dispatch }) => {
        commit('SET_READ_AS_STREAM', dispatch)
      },
      readLine: ({ state, dispatch }, lineIndex) => {
        return new Promise((resolve, reject) => {
          dispatch('buildOffset', lineIndex).then(() => {
            if (state.offsets.length > lineIndex + 1) {
              const start = state.offsets[lineIndex]
              const end = state.offsets[lineIndex + 1] - 1
              dispatch('readSlice', { start, end }).then(result => {
                const decoded = new TextDecoder(state.file.encoding).decode(result)
                resolve(decoded)
              }).catch(err => {
                reject(err)
              })
            } else {
              resolve(undefined)
            }
          })
        })
      },
      readSlice: ({ commit, state }, { start, end }) => {
        return new Promise((resolve, reject) => {
          const reader = new FileReader()
          reader.onerror = (event) => {
            const { target: { error } = {} } = event
            commit('SET_ERROR', error)
            reader.abort()
            reject(error)
          }
          reader.onload = (event) => {
            const { target: { result } = {} } = event
            resolve(new Uint8Array(result))
          }
          start = Math.min(start, state.file.size)
          end = Math.min(end, state.file.size)
          const slice = state.blob.slice(start, end, state.file.type)
          reader.readAsArrayBuffer(slice)
        })
      },
      buildOffset: ({ commit, state, dispatch }, lineIndex) => {
        return new Promise((resolve, reject) => {
          const scan = async (index, start) => {
            const end = start + state.chunkSize
            let offset
            if (index <= lineNumber && state.offsets[index - 1] !== null) {
              await dispatch('readSlice', { start, end }).then(result => {
                for(let c = 0; c <= result.length; c++) {
                  offset = start + c
                  if (offset === state.file.size) { // EOF
                    commit('SET_OFFSET', { index, offset: null })
                    resolve()
                    return
                  } else if (result[c] === 10) { // EOL
                    commit('SET_OFFSET', { index: index++, offset: offset + 1 })
                  }
                }
                start += state.chunkSize
                scan(index, start) // recurse
              }).catch(error => {
                reject(error)
              })
            } else {
              resolve()
            }
          }
          const lineNumber = lineIndex + 1
          let index = state.offsets.length
          if (index <= lineNumber && state.offsets[index - 1] !== null) {
            let start = state.offsets[index - 1] // start at last known offset
            scan(index, start)
          } else {
            resolve()
          }
        })
      }
    }

    const mutations = {
      SET_PERCENT: (state, percent) => {
        state.percent = percent
      },
      SET_READ_AS_TEXT: (state) => {
        const reader = new FileReader()
        reader.onprogress = (event) => {
          state.status = types.LOADING
          const { lengthComputable, loaded, total } = event
          let percent = 0
          if (lengthComputable) {
            percent = Math.round((loaded / total) * 100)
          }
          state.file.percent = percent
        }
        reader.onload = (event) => {
          state.status = types.SUCCESS
          const { target: { result } = {} } = event
          state.file.result = result
        }
        reader.onerror = (event) => {
          state.status = types.ERROR
          const { target: { error: { code, message, name } = {} } = {} } = event
          state.file.error = { code, message, name }
        }
        reader.readAsText(state.blob, state.file.encoding)
      },
      SET_READ_AS_STREAM: (state, dispatch) => {
        state.file.result = new Proxy([], {
          get: (target, prop, receiver) => {
            if (`${+prop}` === prop) { // array index (integer)
              return dispatch('readLine', +prop)
            }
            if (prop === 'length') {
              return state.offsets.length
            }
            if (prop === 'toJSON') {
return null
//              return () => target
            }
            return Reflect.get(target, prop, receiver)
          }
        })
      },
      SET_ENCODING: (state, encoding) => {
        state.encoding = encoding
      },
      SET_CHUNK_SIZE: (state, chunkSize) => {
        state.chunkSize = chunkSize
      },
      SET_ERROR: (state, error) => {
        state.status = types.ERROR
        const { code, message, name } = error
        state.file.error = { code, message, name }
      },
      SET_OFFSET: (state, { index, offset }) => {
console.log('SET_OFFSET', index, offset)
        state.offsets[index] = offset
      }
    }

    return {
      namespaced: true,
      state,
      getters,
      actions,
      mutations
    }
  }
}
