path = require 'path'
fs = require 'fs'
_ = require 'lodash'
cp = require 'child_process'

test_file_path = "#{process.env.HOME}/big_lines.txt"

remove_lines_from_file_by_stream = (file_path, lines)->
  new Promise (resolve, reject)->
    tmp_file_path = "/tmp/#{path.basename(file_path)}"
    src = fs.createReadStream(file_path, 'utf8')
    dst = fs.createWriteStream(tmp_file_path, 'utf8')
    @buffer = ''
    src.on 'error', (err)=>
      reject(err)
    src.on 'data', (chunk)=>
      @buffer += chunk
      sp = @buffer.split /\r?\n/
      @buffer = sp.pop()
      console.log "buffer: #{@buffer}"
      sp.map (src_line)->
        found = _.find lines, (line)-> line == src_line
        unless found
          dst.write src_line + '\n'
    src.on 'end', ()=>
      if @buffer != ''
        sp = @buffer.split /\r?\n/
        sp.map (src_line)->
          found = _.find lines, (line)-> line == src_line
          unless found
            dst.write src_line + '\n'
      dst.end()
      resolve()

remove_lines_from_file_by_grep_v = (file_path, lines)->
  new Promise (resolve, reject)->
    tmp_file_path = "/tmp/#{path.basename(file_path)}"
    command = "cat #{file_path} "
    command += (_.map lines, (line)-> "| grep -v '#{line}'").join " "
    command += " > #{tmp_file_path}"
    cp.exec command, {cwd: '/tmp'}, (err, stdout, stderr)->
      if err
        message = "err: #{err}"
        console.log message
        resolve()
      else
        if stderr
          message = "stderr: #{stderr}"
          console.log message
        if stdout
          message = "stdout: #{stdout}"
          console.log message
        resolve()


create_line = (num)-> "line no. #{num} this is big lines"

create_big_lines = (file_path, num=10000)->
  new Promise (resolve, reject)->
    dst = fs.createWriteStream(file_path)
    for i in [0..num]
      dst.write create_line(i) + '\n'
    dst.end ()->
      resolve()

test_remove_special_lines = ()->
  remove_lines = [10, 100, 1000, 5000, 10000].map create_line
  await create_big_lines(test_file_path)
#  await remove_lines_from_file_by_stream(test_file_path, remove_lines)
  await remove_lines_from_file_by_grep_v(test_file_path, remove_lines)

test_remove_special_lines()










