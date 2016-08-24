using UnityEngine;
using System.Collections;

public class Rotate : MonoBehaviour
{
	public float Rate;

	private void Update ()
	{
        var oldRot = transform.rotation.eulerAngles;
	    var newY = oldRot.y + Rate * Time.deltaTime;
	    transform.rotation = Quaternion.Euler(oldRot.x, newY, oldRot.z);
	}
}
