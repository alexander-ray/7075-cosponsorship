module DataManifest

using JSON


LEG_TYPES = ["hr", "s", "hjres", "sjres", "hconres", "sconres", "hres", "sres"]
MANIFEST_FILE_NAME = "manifest.json"

abstract type ManifestType end
struct PropublicaManifestType <: ManifestType end
struct TextManifestType <: ManifestType end

struct CongressIdentifier
    congress
    legislation_type
    legislation_number
end

MANIFEST_BASE_PATH = Dict{Type{<:ManifestType}, String}(
    PropublicaManifestType=>"/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/ProPublicaBulkBills",
    TextManifestType=>"/Users/alexray/Dropbox/PhD/Courses/Fall21/PSCI7075/Project/Data/Raw/BillText"
)
MANIFEST_DATA_FILE_NAME = Dict{Type{<:ManifestType}, String}(
    PropublicaManifestType=>"data.json",
    TextManifestType=>"data.html"
)

function path_getter(root::String, ::Type{PropublicaManifestType})
    root_parts = split(root, "/")
    congress = root_parts[13]
    legislation_type = root_parts[15]
    legislation_number = replace(root_parts[16], r"[^0-9]+" => s"")
    return CongressIdentifier(congress, legislation_type, legislation_number)
end

function path_getter(root::String, ::Type{TextManifestType})
    root_parts = split(root, "/")
    congress = root_parts[12]
    legislation_type = root_parts[13]
    legislation_number = replace(root_parts[14], r"[^0-9]+" => s"")
    return CongressIdentifier(congress, legislation_type, legislation_number)
end

function build_manifest(
    manifestType::Type{<:ManifestType},
    overwrite=false
)
    base_path = MANIFEST_BASE_PATH[manifestType]
    data_file_name = MANIFEST_DATA_FILE_NAME[manifestType]
    itr = walkdir(base_path)

    if (isfile("$base_path/$MANIFEST_FILE_NAME") && !overwrite)
        return
    end

    manifest = Dict{String, Dict{String, Dict{String, String}}}()

    for congress in 103:115
        manifest[string(congress)] = Dict{String, Dict{String, String}}()
        for leg_type in LEG_TYPES
            manifest[string(congress)][leg_type] = Dict{String, String}()
        end
    end

    for (root, _, files) in itr
        if (data_file_name in files)
            congressIdentifier = path_getter(root, manifestType)
            if (congressIdentifier.legislation_type ∉ LEG_TYPES) 
                continue
            end

            manifest[congressIdentifier.congress][congressIdentifier.legislation_type][congressIdentifier.legislation_number] = "$root/$data_file_name"
        end
    end

    return manifest
end

function load_manifest(manifestType::Type{<:ManifestType})
    base_path = MANIFEST_BASE_PATH[manifestType]
    return JSON.parsefile("$base_path/$MANIFEST_FILE_NAME")
end

export load_manifest, build_manifest, PropublicaManifestType, TextManifestType, CongressIdentifier

end