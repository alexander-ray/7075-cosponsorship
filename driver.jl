include("ProPublicaManifest.jl")
using .ProPublicaManifest
using HTTP
using JSON

function get_bill_text(bill_type::String, bill_num::String, congress::String, api_key::String)::String
    response = HTTP.request("GET", "https://api.fdsys.gov/link?collection=bills&billtype=$bill_type&billnum=$bill_num&congress=$congress&link-type=html&api_key=$api_key")
    return String(response.body)
end

BASE_BILL_TEXT_PATH = "/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText"

DENYLIST = [
    "/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText/103/hr/419",
    "/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText/104/s/1795",
    "/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText/106/s/2545",
    "/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText/106/s/3126"
]

manifest = load_manifest()

for (congress, leg_dict) in manifest
    # if (congress != "103")
    #     continue
    # end
    for (leg_type, num_dict) in leg_dict
        if (leg_type != "s")
            continue
        end

        Threads.@threads for (leg_num, path) in collect(num_dict)
            path = "$BASE_BILL_TEXT_PATH/$congress/$leg_type/$leg_num"
            if (isfile("$path/data.html") || path in DENYLIST)
                continue
            end
    
            println(path)
            text = get_bill_text(leg_type, leg_num, congress)
            mkpath(path)
            open("$path/data.html","w") do io
                print(io, text)
            end
        end
    end
end

