const config = require('./config');
const misc = require('./misc');
const fs = require('fs');
const path = require('path');
const jsdom = require('jsdom');
const {JSDOM} = jsdom;
const fastcsv = require('fast-csv');
var loader = require('csv-load-sync');
const Shell = require('node-powershell');

try {
    clearData();
    const schoolSections = createSections(config.importFiles[2]);
    const studentGroups = enrollUser(config.importFiles[0]);
    const teacherGroups = enrollUser(config.importFiles[1]);
    const students = createUsers(config.importFiles[3],studentGroups,schoolSections);
    const teachers = createUsers(config.importFiles[4],teacherGroups,schoolSections);
    writeFile('Groups.csv',schoolSections);
    writeFile('Students.csv',students);
    writeFile('Teachers.csv',teachers);

    runScripts().then(r => {
        console.log('Operation finished successful');
    });

} catch(e){
    console.log('########################');
    console.log('#########ERROR##########');
    console.log('########################');
    console.log(e);
    console.log('########################');
    console.log('#########ERROR##########');
    console.log('########################');
    process.exit(1);
}

/**
 * Runs powershell script
 * @returns {Promise<void>}
 */
async function runScripts(){
    const ps = new Shell({
        verbose: true,
        executionPolicy: 'Bypass',
        noProfile: true
    });

    if (fs.existsSync(path.resolve('export', 'text.txt'))) {
        fs.unlinkSync(path.resolve('export', 'text.txt'));
    }

    await ps.addCommand(path.resolve('scripts', config.runscript + '.ps1') + ' ' + config.username + ' ' + config.password + ' ' + config.domain);
    ps.invoke()
        .then(output => {
            console.log(output);
            ps.dispose();
        })
        .catch(err => {
            console.log(err);
            ps.dispose();
        });
    ps.on('end', code => {
    });
}

/**
 * Write new csv file for powershell script
 * @param filename
 * @param data
 * @returns {Promise<void>}
 */
async function writeFile(filename,data){
    const ws = fs.createWriteStream(path.resolve('export', filename));
    fastcsv
        .write(data, {headers: true})
        .pipe(ws);
}

/**
 * Get school sections array
 * @param filename
 * @returns {[]}
 */
function createSections(filename){
    var sections = [];
    var results = loader(path.resolve('import',filename));
    results.forEach(function(e){
        sections.push({
            'id': e['SIS ID'],
            'name': e['Section Name'].toUpperCase(),
            'alias': misc.removeDiacritics(e['Section Name']),
        })
    });
    return sections;
}

/**
 * Enroll user to school section
 * @param filename
 * @returns {[]}
 */
function enrollUser(filename){
    var groups = [];
    var results = loader(path.resolve('import',filename));
    results.forEach(function(e){
        groups.push({
            'group': e['Section SIS ID'],
            'user': e['SIS ID'],
        })
    });
    return groups;
}

/**
 * Get array of users
 * @param filename
 * @param groups
 * @param sections
 * @returns {[]}
 */
function createUsers(filename,groups,sections){
    var users = [];
    var results = loader(path.resolve('import',filename));
    results.forEach(function(e){
        var Enroll = '';
        groups.filter(element => element.user === e['SIS ID']).forEach(a => {
            sections.filter(el => el.id === a.group).forEach(b => {
                Enroll += b.alias + '*';
            })
        })
        users.push({
            'id': e['SIS ID'],
            'name': e['First Name'].toUpperCase(),
            'surname': e['Last Name'].toUpperCase(),
            'password': e['Password'],
            'email': misc.removeDiacritics(e['First Name']).toUpperCase() + '.' + misc.removeDiacritics(e['Last Name']).toUpperCase() + config.domain,
            'groups': Enroll.slice(0,-1)
        })
    });
    return users;
}

/**
 * Clean export folder and check for csv to import
 */
function clearData(){
    if (fs.existsSync(path.resolve('export', 'Student.csv'))) {
        fs.unlinkSync(path.resolve('export', 'Student.csv'));
    }
    if (fs.existsSync(path.resolve('export', 'Groups.csv'))) {
        fs.unlinkSync(path.resolve('export', 'Groups.csv'));
    }
    if (fs.existsSync(path.resolve('export', 'Teachers.csv'))) {
        fs.unlinkSync(path.resolve('export', 'Teachers.csv'));
    }
    config.importFiles.forEach(function (e) {
        if (!fs.existsSync(path.resolve('import', e))) {
            throw new Error('FILE NOT FOUND: import/' + e);
        }
    });
}