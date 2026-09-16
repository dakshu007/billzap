/**
 * BillZap — download email capture.
 *
 * Receives one email address per download from the landing page and
 * appends it to the bound spreadsheet.
 *
 * The page posts with Content-Type: text/plain and mode: 'no-cors'.
 * That is deliberate, not sloppiness: an Apps Script web app does not
 * answer the CORS preflight, so the request has to stay a "simple"
 * one. The consequence is that the browser cannot read this reply, so
 * the page never waits for it and a failure here can never stand
 * between a visitor and the APK.
 *
 * Deploy: Extensions -> Apps Script, paste this, then
 * Deploy -> New deployment -> Web app
 *   Execute as:        Me
 *   Who has access:    Anyone
 * Copy the /exec URL into SHEET_ENDPOINT in landing-page/build/build.py
 * and rebuild.
 */

/** Tab to write to. Created on first use if missing. */
var SHEET_NAME = 'Downloads';

/** Columns, in order. Changing this changes new rows only. */
var HEADERS = ['Timestamp', 'Email', 'Domain', 'Source'];

function doPost(e) {
  try {
    var raw = (e && e.postData && e.postData.contents) || '{}';
    var data = JSON.parse(raw);
    var email = String(data.email || '').trim().toLowerCase();

    // The page validates before sending; this is the second gate,
    // because a web app deployed to "Anyone" is a public URL and
    // anything at all can POST to it.
    if (!isPlausibleEmail(email)) {
      return reply({ ok: false, error: 'invalid email' });
    }

    var sheet = getSheet();

    // One row per address. A second download from the same person
    // updates the timestamp rather than adding a duplicate, so the
    // sheet stays a list of people rather than a list of clicks.
    var existing = findRow(sheet, email);
    var now = new Date();
    var row = [now, email, email.slice(email.indexOf('@') + 1),
               String(data.source || '')];

    if (existing > 0) {
      sheet.getRange(existing, 1, 1, HEADERS.length).setValues([row]);
      return reply({ ok: true, updated: true });
    }
    sheet.appendRow(row);
    return reply({ ok: true, added: true });

  } catch (err) {
    console.error(err);
    return reply({ ok: false, error: String(err) });
  }
}

/** A GET is handy for checking the deployment is alive. */
function doGet() {
  return reply({ ok: true, service: 'billzap-downloads' });
}

function getSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(HEADERS);
    sheet.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold');
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function findRow(sheet, email) {
  var last = sheet.getLastRow();
  if (last < 2) return 0;
  var col = sheet.getRange(2, 2, last - 1, 1).getValues();
  for (var i = 0; i < col.length; i++) {
    if (String(col[i][0]).trim().toLowerCase() === email) return i + 2;
  }
  return 0;
}

function isPlausibleEmail(v) {
  return v.length > 3 && v.length < 255 &&
    /^[^\s@]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,24}$/.test(v);
}

function reply(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
