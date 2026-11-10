---- MODULE LocalURLShortener ----
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS MaxCode, Accounts, Browsers, ValidDestinations, InvalidDestinations

ASSUME MaxCode \in Nat
ASSUME MaxCode >= 3
ASSUME Cardinality(Accounts) = 2
ASSUME Cardinality(Browsers) = 2
ASSUME Cardinality(ValidDestinations) >= 2
ASSUME Cardinality(InvalidDestinations) >= 1

RuntimeStates == {"Starting", "Serving", "StartupFailed"}
NoAccount == "SignedOut"
NoToken == "NoToken"
NoDestination == "NoDestination"
Codes == 1..MaxCode
InputDestinations == ValidDestinations \cup InvalidDestinations
AccountValues == Accounts \cup {NoAccount}
Token(b) == b
Tokens == {NoToken} \cup {Token(b) : b \in Browsers}
ValidCSRF(b, t) == t = Token(b)

LinkRecord == [owner : AccountValues, destination : ValidDestinations \cup {NoDestination}]
DestinationValues == ValidDestinations \cup {NoDestination}
RequestKinds == {"none", "list", "create", "remove", "resolve"}
ResponseKinds == {"none", "listed", "created", "removed", "redirect", "not_found", "rejected"}
ResponseDestinations == ValidDestinations \cup InvalidDestinations \cup {NoDestination}
RequestRecord == [
    kind : RequestKinds,
    accepted : BOOLEAN,
    runtime : RuntimeStates,
    session : AccountValues,
    csrf_ok : BOOLEAN,
    owner : AccountValues,
    code : 0..MaxCode,
    destination : ResponseDestinations
]
ResponseRecord == [
    kind : ResponseKinds,
    status : 0..599,
    code : 0..MaxCode,
    destination : ResponseDestinations
]
StoreRecord == [
    active : SUBSET Codes,
    links : [Codes -> LinkRecord],
    assigned : [Codes -> DestinationValues],
    retired : SUBSET Codes,
    allocated : SUBSET Codes,
    next : 1..(MaxCode + 1)
]

InitialLinks == [c \in Codes |-> [owner |-> NoAccount, destination |-> NoDestination]]
InitialAssigned == [c \in Codes |-> NoDestination]

VARIABLES
    runtime,
    sessions,
    csrf,
    active,
    links,
    assigned,
    retired_ids,
    allocated_ids,
    next_id,
    visible,
    last_request,
    last_response,
    last_store,
    restart_pending,
    restart_snapshot

vars == <<
    runtime, sessions, csrf, active, links, assigned, retired_ids,
    allocated_ids, next_id, visible, last_request, last_response,
    last_store, restart_pending, restart_snapshot
>>

View == <<
    runtime, sessions, csrf, active, links, assigned, retired_ids,
    allocated_ids, next_id, visible, restart_pending, restart_snapshot
>>

Store == [
    active |-> active,
    links |-> links,
    assigned |-> assigned,
    retired |-> retired_ids,
    allocated |-> allocated_ids,
    next |-> next_id
]

InitialRequest == [
    kind |-> "none",
    accepted |-> FALSE,
    runtime |-> "Starting",
    session |-> NoAccount,
    csrf_ok |-> FALSE,
    owner |-> NoAccount,
    code |-> 0,
    destination |-> NoDestination
]

InitialResponse == [kind |-> "none", status |-> 0, code |-> 0, destination |-> NoDestination]

Init ==
    /\ runtime = "Starting"
    /\ sessions = [b \in Browsers |-> NoAccount]
    /\ csrf = [b \in Browsers |-> NoToken]
    /\ active = {}
    /\ links = InitialLinks
    /\ assigned = InitialAssigned
    /\ retired_ids = {}
    /\ allocated_ids = {}
    /\ next_id = 1
    /\ visible = [b \in Browsers |-> {}]
    /\ last_request = InitialRequest
    /\ last_response = InitialResponse
    /\ last_store = Store
    /\ restart_pending = FALSE
    /\ restart_snapshot = Store

ResetObservation ==
    /\ last_request' = [
        kind |-> "none",
        accepted |-> FALSE,
        runtime |-> runtime,
        session |-> NoAccount,
        csrf_ok |-> FALSE,
        owner |-> NoAccount,
        code |-> 0,
        destination |-> NoDestination
        ]
    /\ last_response' = InitialResponse
    /\ last_store' = Store

RecordRequest(b, kind, accepted, owner, code, destination, csrf_ok, response_kind, response_status, response_code, response_destination) ==
    /\ last_request' = [
        kind |-> kind,
        accepted |-> accepted,
        runtime |-> runtime,
        session |-> sessions[b],
        csrf_ok |-> csrf_ok,
        owner |-> owner,
        code |-> code,
        destination |-> destination
        ]
    /\ last_response' = [
        kind |-> response_kind,
        status |-> response_status,
        code |-> response_code,
        destination |-> response_destination
        ]
    /\ last_store' = Store

RecordPublic(c, response_kind, response_status, response_destination) ==
    /\ last_request' = [
        kind |-> "resolve",
        accepted |-> TRUE,
        runtime |-> runtime,
        session |-> NoAccount,
        csrf_ok |-> FALSE,
        owner |-> NoAccount,
        code |-> c,
        destination |-> NoDestination
        ]
    /\ last_response' = [
        kind |-> response_kind,
        status |-> response_status,
        code |-> c,
        destination |-> response_destination
        ]
    /\ last_store' = Store

StartServing ==
    /\ runtime = "Starting"
    /\ runtime' = "Serving"
    /\ restart_pending' = FALSE
    /\ UNCHANGED <<sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_snapshot>>
    /\ ResetObservation

FailStartup ==
    /\ runtime = "Starting"
    /\ runtime' = "StartupFailed"
    /\ UNCHANGED <<sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ ResetObservation

RetryStartup ==
    /\ runtime = "StartupFailed"
    /\ runtime' = "Starting"
    /\ UNCHANGED <<sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ ResetObservation

Restart ==
    /\ runtime = "Serving"
    /\ runtime' = "Starting"
    /\ restart_pending' = TRUE
    /\ restart_snapshot' = Store
    /\ visible' = [b \in Browsers |-> {}]
    /\ UNCHANGED <<sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id>>
    /\ ResetObservation

SignIn(b, a) ==
    /\ runtime = "Serving"
    /\ a \in Accounts
    /\ sessions' = [sessions EXCEPT ![b] = a]
    /\ csrf' = [csrf EXCEPT ![b] = Token(b)]
    /\ visible' = [visible EXCEPT ![b] = {}]
    /\ UNCHANGED <<runtime, active, links, assigned, retired_ids, allocated_ids, next_id, restart_pending, restart_snapshot>>
    /\ ResetObservation

SignOut(b) ==
    /\ runtime = "Serving"
    /\ sessions' = [sessions EXCEPT ![b] = NoAccount]
    /\ csrf' = [csrf EXCEPT ![b] = NoToken]
    /\ visible' = [visible EXCEPT ![b] = {}]
    /\ UNCHANGED <<runtime, active, links, assigned, retired_ids, allocated_ids, next_id, restart_pending, restart_snapshot>>
    /\ ResetObservation

ListAccepted(b) ==
    /\ runtime = "Serving"
    /\ sessions[b] # NoAccount
    /\ visible' = [visible EXCEPT ![b] = {c \in active : links[c].owner = sessions[b]}]
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "list", TRUE, sessions[b], 0, NoDestination, FALSE, "listed", 0, 0, NoDestination)

ListRejected(b) ==
    /\ runtime = "Serving"
    /\ sessions[b] = NoAccount
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "list", FALSE, NoAccount, 0, NoDestination, FALSE, "rejected", 0, 0, NoDestination)

CreateGuard(b, d, t) ==
    /\ runtime = "Serving"
    /\ sessions[b] # NoAccount
    /\ ValidCSRF(b, t)
    /\ d \in ValidDestinations
    /\ next_id <= MaxCode

CreateAccepted(b, d, t) ==
    /\ CreateGuard(b, d, t)
    /\ active' = active \cup {next_id}
    /\ links' = [links EXCEPT ![next_id] = [owner |-> sessions[b], destination |-> d]]
    /\ assigned' = [assigned EXCEPT ![next_id] = d]
    /\ allocated_ids' = allocated_ids \cup {next_id}
    /\ next_id' = next_id + 1
    /\ retired_ids' = retired_ids
    /\ visible' = [b2 \in Browsers |-> {}]
    /\ UNCHANGED <<runtime, sessions, csrf, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "create", TRUE, sessions[b], next_id, d, TRUE, "created", 0, next_id, d)

CreateRejected(b, d, t) ==
    /\ runtime = "Serving"
    /\ ~CreateGuard(b, d, t)
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "create", FALSE, sessions[b], 0, d, ValidCSRF(b, t), "rejected", 0, 0, d)

RequestedOwner(c) == IF c \in active THEN links[c].owner ELSE NoAccount

RemoveGuard(b, c, t) ==
    /\ runtime = "Serving"
    /\ sessions[b] # NoAccount
    /\ ValidCSRF(b, t)
    /\ c \in active
    /\ links[c].owner = sessions[b]

RemoveAccepted(b, c, t) ==
    /\ RemoveGuard(b, c, t)
    /\ active' = active \ {c}
    /\ retired_ids' = retired_ids \cup {c}
    /\ allocated_ids' = allocated_ids
    /\ links' = links
    /\ assigned' = assigned
    /\ next_id' = next_id
    /\ visible' = [b2 \in Browsers |-> {}]
    /\ UNCHANGED <<runtime, sessions, csrf, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "remove", TRUE, links[c].owner, c, NoDestination, TRUE, "removed", 0, c, NoDestination)

RemoveRejected(b, c, t) ==
    /\ runtime = "Serving"
    /\ ~RemoveGuard(b, c, t)
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ RecordRequest(b, "remove", FALSE, RequestedOwner(c), c, NoDestination, ValidCSRF(b, t), "rejected", 0, c, NoDestination)

ResolveActive(c) ==
    /\ runtime = "Serving"
    /\ c \in active
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ RecordPublic(c, "redirect", 302, links[c].destination)

ResolveMissing(c) ==
    /\ runtime = "Serving"
    /\ c \notin active
    /\ UNCHANGED <<runtime, sessions, csrf, active, links, assigned, retired_ids, allocated_ids, next_id, visible, restart_pending, restart_snapshot>>
    /\ RecordPublic(c, "not_found", 404, NoDestination)

Next ==
    \/ StartServing
    \/ FailStartup
    \/ RetryStartup
    \/ Restart
    \/ \E b \in Browsers, a \in Accounts : SignIn(b, a)
    \/ \E b \in Browsers : SignOut(b)
    \/ \E b \in Browsers : ListAccepted(b) \/ ListRejected(b)
    \/ \E b \in Browsers, d \in InputDestinations, t \in Tokens : CreateAccepted(b, d, t) \/ CreateRejected(b, d, t)
    \/ \E b \in Browsers, c \in Codes, t \in Tokens : RemoveAccepted(b, c, t) \/ RemoveRejected(b, c, t)
    \/ \E c \in Codes : ResolveActive(c) \/ ResolveMissing(c)

DurableState == Store

TypeOK ==
    /\ runtime \in RuntimeStates
    /\ sessions \in [Browsers -> AccountValues]
    /\ csrf \in [Browsers -> Tokens]
    /\ active \subseteq Codes
    /\ links \in [Codes -> LinkRecord]
    /\ assigned \in [Codes -> DestinationValues]
    /\ retired_ids \subseteq Codes
    /\ allocated_ids \subseteq Codes
    /\ next_id \in 1..(MaxCode + 1)
    /\ visible \in [Browsers -> SUBSET Codes]
    /\ last_request \in RequestRecord
    /\ last_response \in ResponseRecord
    /\ last_store \in StoreRecord
    /\ restart_pending \in BOOLEAN
    /\ restart_snapshot \in StoreRecord

OnlyServingAcceptsRequests ==
    last_request.kind # "none" => last_request.runtime = "Serving"

MutationBoundary ==
    last_request.kind \in {"create", "remove"}
        /\ last_request.accepted
        => /\ last_request.runtime = "Serving"
           /\ last_request.session # NoAccount
           /\ last_request.csrf_ok
           /\ last_request.owner = last_request.session

RejectedMutationPreservesStore ==
    last_request.kind \in {"create", "remove"}
        /\ ~last_request.accepted
        => DurableState = last_store

ActiveLinkIntegrity ==
    \A c \in active :
        /\ links[c].owner \in Accounts
        /\ links[c].destination \in ValidDestinations

VisibleListsOwnerOnly ==
    \A b \in Browsers :
        /\ visible[b] \subseteq active
        /\ \A c \in visible[b] :
            /\ sessions[b] # NoAccount
            /\ links[c].owner = sessions[b]

CodeHistory ==
    /\ active \cap retired_ids = {}
    /\ active \cup retired_ids = allocated_ids
    /\ allocated_ids = 1..(next_id - 1)
    /\ \A c \in allocated_ids : assigned[c] \in ValidDestinations

FreshCodeOnCreate ==
    last_request.kind = "create"
        /\ last_request.accepted
        => /\ last_request.code \notin last_store.allocated
           /\ last_store.assigned[last_request.code] = NoDestination

ResponseCorrect ==
    /\ last_response.kind = "redirect"
        => /\ last_response.status = 302
           /\ last_response.code \in active
           /\ last_response.destination = links[last_response.code].destination
    /\ last_response.kind = "not_found"
        => /\ last_response.status = 404
           /\ last_response.code \notin active
    /\ last_response.kind = "created"
        => /\ last_response.code \in active
           /\ links[last_response.code].owner = last_request.session
           /\ links[last_response.code].destination = last_response.destination
    /\ last_response.kind = "removed"
        => /\ last_response.code \in retired_ids
           /\ last_response.code \notin active

PublicResolutionIsSessionFree ==
    last_request.kind = "resolve" => last_request.session = NoAccount

PublicResolutionDoesNotMutateStore ==
    last_request.kind = "resolve" => DurableState = last_store

RestartPreservesDurableState ==
    /\ (~restart_pending => TRUE)
    /\ (restart_pending => DurableState = restart_snapshot)

Spec == Init /\ [][Next]_vars

=============================================================================
