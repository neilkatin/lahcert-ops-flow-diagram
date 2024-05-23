#! /bin/bash

declare -i ERRORS=0
declare -i DEBUG=0
declare OUTPUT_FILE=ops-flow.html

function main() {
    header
    body
    footer
}

function expand() {
    local description="$1"; shift
    local -a args=( "$@" )

    if [ "$*" = "COLSPAN" ]; then
        echo "    <tr>"
        echo "      <td colspan='2'>"
        echo "        $description"
        echo "      </td>"
        echo "    </tr>"
    else

        local -a sed_args

        local a
        for a in "${args[@]}"; do
            D "arg is '$a'"

            local key="${a%%=*}"
            local value="${a#*=}"

            if [ "$key" = "$a" ]; then
                E "all keys must have an '=' character.  Got '$a'"
            fi

            sed_args+=( -e "s/%$key%/$value/" )
        done

        if (( $ERRORS != 0 )); then
            exit 1
        fi

        D "sed_args: '${sed_args[*]}'"

        echo "    <tr>"
        echo "      <td>"
        echo "        $description"
        echo "      </td>"
        echo "      <td>"

        cat ops-flow.template | \
            sed "${sed_args[@]}" -e 's/%[^%]*%//' | \
            dot "-Tsvg:svg:core" | \
            sed -e '1,/^<!-- Title:/d'

        echo "      </td>"
        echo "    </tr>"
    fi
}

function header() {
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <style>
  table.flow, .flow th, .flow td { border: 2px solid; border-collapse: collapse; }
  </style>
</head>
<body>
  <table class="flow">

EOF
}

function footer() {
    cat << EOF


  </table>
  <p>generated on $(date '+%Y-%m-%d %H:%M:%S')</p>
</body>
</html>
EOF
}

function body() {
expand "
<p>This document is a short guide to how the
Los Altos Hills Community Emergency Response Team (LAH-CERT)
ARK information flow works.
</p>

<p>
This doc just gives an overview.  A more complete reference can be found on our
<a href='https://cert.lahcfd.org/procedures'>procedures page</a>.
Look for the LAH CERT Operations Procedures for the process, and Ops Forms for the blank forms we use.
</p>
The 
" COLSPAN

expand "This chart will be used throughout the explanation.  Each circle is a 'position' that may be staffed in a CERT activation"

expand "Just starting up; no ad-hoc assignments.  Recon will use the first pre-planned task and assign it to a free field team" \
    NODE_RECON=style=filled NODE_FIELD_1=style=filled EDGE_RECON_FIELD_1='dir=forward label="preplanned assignment 1"'

expand "Still no ad-hoc assignments.  Recon will use the second pre-planned task and assign it to a free field team" \
    NODE_RECON=style=filled NODE_FIELD_2=style=filled EDGE_RECON_FIELD_2='dir=forward label="preplanned assignment 2"'

expand "Periodically Recon will send a copy of its Preplanned and Ad Hoc tracking froms to Ops (and Scribe, IT, and Planning; not shown here for simplicity)" \
    NODE_RECON=style=filled NODE_OPS=style=filled EDGE_OPS_RECON='dir=back label="Tracking Forms"'

expand "The first field team finishes its assignment, and lets Recon know.  Recon updates the Preplanned assignment tracker." \
    NODE_RECON=style=filled NODE_FIELD_1=style=filled EDGE_RECON_FIELD_1='dir=back label="Verbal over radio"' 


expand "Recon will continue to make pre-planned assignments as long as there are available field teams.  Recon will use the third pre-planned task and assign it to a free field team" \
    NODE_RECON=style=filled NODE_FIELD_1=style=filled EDGE_RECON_FIELD_1='dir=forward label="preplanned assignment 3"'

expand "Alert: the EOC has an urgent task for CERT: the Mayor's cat is stuck in a tree!  The message might be on a form, or via a phone call or email." \
    NODE_OPS=style=filled NODE_EOC=style=filled EDGE_OPS_EOC='dir=back label="Message\nfrom the EOC"'

expand "Ops is all over this request.  They send an Ops Assignment form to Recon with a priority of 1 (preempt existing surveys)" \
    NODE_OPS=style=filled NODE_RECON=style=filled EDGE_OPS_RECON='dir=forward label="Ops Assignment Form"'

expand "Recon contacts the field team closest to the Mayor's house (field team 2 in this case).  Recon instructs the field team to stop its current task, and switch to this new one.  Recon passes along the key info on the Ops Assignment form" \
    NODE_RECON=style=filled NODE_FIELD_2=style=filled EDGE_RECON_FIELD_2='dir=forward label="via voice, info from\nOps Assignment Form"'

expand "Someone calls the ARK phone.  Dru's horse is loose.  Poor Dru." \
    NODE_OPS=style=filled NODE_COMMS=style=filled EDGE_OPS_COMMS='dir=back label="via phone,\ndocumented on LAH102 form"'

expand "Ops evaluates report, decides someone should check it out, but no need to preempt a field team (priority 2).  Ops makes another Ops Assignment form and sends it to Recon" \
    NODE_OPS=style=filled NODE_RECON=style=filled EDGE_OPS_RECON='dir=forward label="Ops Assignment form"'

expand "Recon sends another copy of its tracking forms to Ops (and Scribe, IT, and Planning; not shown here for simplicity) so everyone knows the current status.  We won't call this out any more in this tutorial, but Recon should update Ops often enough that Ops is up to date (and whenever Ops asks)" \
    NODE_RECON=style=filled NODE_OPS=style=filled EDGE_OPS_RECON='dir=back label="Tracking Forms"'

expand "Field team 2 is done rescuing the Mayor's cat and reports status." \
    NODE_RECON=style=filled NODE_FIELD_2=style=filled EDGE_RECON_FIELD_2='dir=back label="Voice Report"'

expand "Since field team 2 is now free: give them the task about Dru's horse" \
    NODE_RECON=style=filled NODE_FIELD_2=style=filled EDGE_RECON_FIELD_2='dir=forward label="via voice, info from\nOps Assignment Form"'

expand "The assignment about the Mayor's cat is complete.  Update the Ops Assignment form and return it to Ops.  (Also make sure tracking form is updated)" \
    NODE_RECON=style=filled NODE_OPS=style=filled EDGE_OPS_RECON='dir=back label="Ops Assignment Form"'


}


function E() {
    echo "Error: $@" 1>&2
    (( ERRORS++ ))
}

function D() {
    if [ "$DEBUG" != "" -a "$DEBUG" != "0" ]; then
        echo "Debug: $@" 1>&2
    fi
}

main "$@" > "$OUTPUT_FILE"
#main "$@"
