# Failure

This document describes how shipment failures are counted and when a run ends.

## Shipment Failures

A shipment failure is counted when an outbound 
order is not shipped before its delivery timer expires.

The failed order is removed. If a package had already been matched
to it, that package reverts to general inventory wherever it
currently is; otherwise only the order itself is lost.

## Failure Limit

The run ends immediately when the total number 
of shipment failures reaches the configured limit.

There are no separate failure conditions for battery, storage pressure,
or an overloaded loading bay. Those systems create problems indirectly
by making it harder to complete outbound orders in time.

## Score

When the run ends, the final score is the number of outbound 
orders successfully completed before the failure limit was reached.
