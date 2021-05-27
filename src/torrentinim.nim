import os
import json
import prologue
import strutils
import parsecfg

import "database"
import "./helpers/datetime"
import "./torrents"
from "./crawlers/eztv" import nil
from "./crawlers/leetx.nim" import nil
from "./crawlers/nyaa.nim" import nil
from "./crawlers/nyaa_pantsu.nim" import nil
from "./crawlers/yts.nim" import nil
from "./crawlers/torrent_downloads.nim" import nil
from "./crawlers/nyaa_sukebei.nim" import nil
from "./crawlers/thepiratebay.nim" import nil
from "./crawlers/rarbg.nim" import nil

import prologue/middlewares/cors

when isMainModule:
  if (initRequested()):
    discard initDatabase()

  var dict = loadConfig("config.ini")
  
  if dict.getSectionValue("Crawlers","eztv")=="on":
    asyncCheck eztv.startCrawl()
  if dict.getSectionValue("Crawlers","leetx")=="on":
    asyncCheck leetx.startCrawl()
  if dict.getSectionValue("Crawlers","nyaa")=="on":
    asyncCheck nyaa.startCrawl()
  if dict.getSectionValue("Crawlers","nyaa_pantsu")=="on":
    asyncCheck nyaa_pantsu.startCrawl()
  if dict.getSectionValue("Crawlers","nyaa_sukebei")=="on":
    asyncCheck nyaa_sukebei.startCrawl()
  if dict.getSectionValue("Crawlers","yts")=="on":
    asyncCheck yts.startCrawl()
  if dict.getSectionValue("Crawlers","torrentdownloads")=="on":
    asyncCheck torrentdownloads.startCrawl()
  if dict.getSectionValue("Crawlers","thepiratebay")=="on":
    asyncCheck thepiratebay.startCrawl()
  if dict.getSectionValue("Crawlers","rarbg")=="on":
    asyncCheck rarbg.startCrawl()

  let settings = newSettings(debug = false, port = Port(getEnv("TORRENTINIM_PORT", "50123").parseInt()))
  var app = newApp(settings = settings)

  proc hello*(ctx: Context) {.async.} =
    resp "Torrentinim is running, bambino."

  proc search*(ctx: Context) {.async.} =
    let query = ctx.getQueryParams("query")
    let page = ctx.getQueryParams("page")
    let results = searchTorrents(query, page)
    resp jsonResponse(%results)

  proc hot*(ctx: Context) {.async.} =
    let page = ctx.getQueryParams("page")
    let results = hotTorrents(page)
    resp jsonResponse(%results)
      
  var allowOrigins = getEnv("ALLOW_ORIGINS", "https://incur.numag.net")
  app.use(CorsMiddleware(allowOrigins = @[allowOrigins]))
  app.addRoute("/", hello)
  app.addRoute("/search", search)
  app.addRoute("/hot", hot)
  app.run()