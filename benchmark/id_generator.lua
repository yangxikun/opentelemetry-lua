local id_generator = require("lib.opentelemetry.trace.id_generator")
local start = os.clock()

for _ = 1, 5000000 do
    id_generator.new_ids()
end

print('fewer random calls, 5m new ids: ' .. (os.clock() - start) ..' seconds.')
